# Separate Template::Plugin::Ovid Concerns - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor `Template::Plugin::Ovid` by extracting tag and pagination concerns into separate focused plugins.

**Architecture:** Split monolithic template plugin into three focused components: core rendering utilities (Ovid.pm), tag operations (Ovid/Tags.pm), and pagination wrapper (Pager.pm). Migrate template includes to use new plugins. Remove dead code.

**Tech Stack:** Perl 5.40+, Template Toolkit, Test::Most, Path::Tiny, Mojo::JSON

---

## Task 1: Create Template::Plugin::Ovid::Tags

**Files:**
- Create: `lib/Template/Plugin/Ovid/Tags.pm`
- Create: `t/ovid_tags_plugin.t`

**Step 1: Write the failing test**

```perl
#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;

# Test the new Tags plugin
subtest 'Tags plugin loads and initializes' => sub {
    require_ok('Template::Plugin::Ovid::Tags');

    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    isa_ok $plugin, 'Template::Plugin::Ovid::Tags';
    ok exists $plugin->{tagmap}, 'Plugin should have tagmap data';
};

done_testing;
```

**Step 2: Run test to verify it fails**

Run: `prove -lv t/ovid_tags_plugin.t`
Expected: FAIL with "Can't locate Template/Plugin/Ovid/Tags.pm"

**Step 3: Write minimal Tags plugin implementation**

```perl
package Template::Plugin::Ovid::Tags;

use Less::Boilerplate;
use Less::Config 'config';
use Mojo::JSON 'decode_json';
use List::Util qw(max min);
use Path::Tiny 'path';
use base 'Template::Plugin';

sub new ( $class, $context ) {
    my $tagmap_file = config()->{tagmap_file};
    my $json        = path($tagmap_file)->slurp_utf8;

    bless {
        _CONTEXT => $context,
        tagmap   => decode_json($json),
    }, $class;
}

sub tags_by_weight ($self) {
    my %tags = map { $_ => $self->weight_for_tag($_) } $self->_tags;

    # Perl's sort is stable, so by sorting the keys, we ensure
    # that tags with equal weight are sorted alphabetically.
    return sort { $tags{$b} <=> $tags{$a} } sort keys %tags;
}

sub _tags ($self) {
    return sort grep { $_ ne '__ALL__' } keys $self->{tagmap}->%*;
}

sub weight_for_tag ( $self, $tag ) {

    # https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
    state $weight_for = {};
    state $weight_max = 9;
    state $weight_min = 1;
    unless ( exists $weight_for->{$tag} ) {
        my $counts = [ map { $self->{tagmap}{$_}{count} } $self->_tags ];
        my $min    = min @$counts;
        my $max    = max @$counts;
        my $count  = $self->{tagmap}{$tag}{count};
        my $weight = $weight_min + ( ( $weight_max - $weight_min ) * ( $count - $min ) ) / ( $max - $min );
        $weight_for->{$tag} = int( $weight + .5 );
    }
    return $weight_for->{$tag};
}

sub name_for_tag ( $self, $tag ) {
    my $name = config()->{tagmap}{$tag}
      or croak("Cannot find name for unknown tag '$tag'");
    return $name;
}

1;

__END__

=head1 NAME

Template::Plugin::Ovid::Tags - Tag operations for Template Toolkit

=head1 SYNOPSIS

    [% USE tags = Ovid.Tags %]
    [% FOREACH tag IN tags.tags_by_weight %]
        <a href="/tags/[% tag %].html"
           data-weight="[% tags.weight_for_tag(tag) %]">
            [% tags.name_for_tag(tag) %]
        </a>
    [% END %]

=head1 METHODS

=head2 C<tags_by_weight()>

Returns list of tags sorted by weight (article count), heaviest first.

=head2 C<weight_for_tag($tag)>

Returns display weight for tag (1-9 scale) based on article count.

=head2 C<name_for_tag($tag)>

Returns display name for tag from config.

=cut
```

**Step 4: Run test to verify it passes**

Run: `prove -lv t/ovid_tags_plugin.t`
Expected: PASS

**Step 5: Add comprehensive tests**

Add to `t/ovid_tags_plugin.t`:

```perl
subtest 'tags_by_weight returns sorted tags' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my @tags   = $plugin->tags_by_weight;

    ok scalar(@tags) > 0, 'Should return some tags';

    # Verify it excludes __ALL__
    ok !( grep { $_ eq '__ALL__' } @tags ), 'Should not include __ALL__';

    # Verify tags are valid (exist in config)
    my $config = config();
    foreach my $tag (@tags) {
        ok exists $config->{tagmap}{$tag}, "Tag '$tag' should exist in config";
    }
};

subtest 'weight_for_tag calculates weights' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my @tags   = $plugin->tags_by_weight;

    foreach my $tag (@tags) {
        my $weight = $plugin->weight_for_tag($tag);
        like $weight, qr/^\d+$/, "Weight for '$tag' should be an integer";
        ok $weight >= 1 && $weight <= 9, "Weight should be 1-9, got $weight";
    }
};

subtest 'name_for_tag returns display names' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my $config = config();

    foreach my $tag ( keys $config->{tagmap}->%* ) {
        my $name = $plugin->name_for_tag($tag);
        is $name, $config->{tagmap}{$tag}, "Name for '$tag' should match config";
    }
};

subtest 'name_for_tag croaks for unknown tag' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);

    throws_ok {
        $plugin->name_for_tag('nonexistent_tag_xyz');
    }
    qr/Cannot find name for unknown tag/, 'Should croak for unknown tag';
};
```

**Step 6: Run full test**

Run: `prove -lv t/ovid_tags_plugin.t`
Expected: All subtests PASS

**Step 7: Commit**

```bash
git add lib/Template/Plugin/Ovid/Tags.pm t/ovid_tags_plugin.t
git commit -m "feat: add Template::Plugin::Ovid::Tags

Extracts tag-related functionality from Template::Plugin::Ovid into
focused plugin for tag operations.

Methods:
- tags_by_weight() - sorted tags by article count
- weight_for_tag() - display weight (1-9 scale)
- name_for_tag() - display name from config

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Create Template::Plugin::Pager

**Files:**
- Create: `lib/Template/Plugin/Pager.pm`
- Create: `t/pager_plugin.t`

**Step 1: Write the failing test**

```perl
#!/usr/bin/env perl

use Test::Most;
use lib 'lib';

subtest 'Pager plugin is thin wrapper for Less::Pager' => sub {
    require_ok('Template::Plugin::Pager');

    my $plugin = Template::Plugin::Pager->new( undef, { type => 'article' } );
    isa_ok $plugin, 'Less::Pager', 'Should return Less::Pager instance';

    can_ok $plugin, qw(prev_post next_post this_post);
};

done_testing;
```

**Step 2: Run test to verify it fails**

Run: `prove -lv t/pager_plugin.t`
Expected: FAIL with "Can't locate Template/Plugin/Pager.pm"

**Step 3: Write Pager plugin implementation**

```perl
package Template::Plugin::Pager;

use v5.40;
use base 'Template::Plugin';
use Less::Pager;

sub new ( $class, $context, $params = {} ) {
    return Less::Pager->new( $params->%* );
}

1;

__END__

=head1 NAME

Template::Plugin::Pager - Thin wrapper for Less::Pager in Template Toolkit

=head1 SYNOPSIS

    [% USE pager = Pager(type => 'article') %]
    [% prev = pager.prev_post(type, slug) %]
    [% next = pager.next_post(type, slug) %]

=head1 DESCRIPTION

This is a thin wrapper that allows Template Toolkit templates to use
C<Less::Pager> directly. All methods are delegated to C<Less::Pager>.

=head1 METHODS

See L<Less::Pager> for method documentation.

=cut
```

**Step 4: Run test to verify it passes**

Run: `prove -lv t/pager_plugin.t`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/Template/Plugin/Pager.pm t/pager_plugin.t
git commit -m "feat: add Template::Plugin::Pager

Thin wrapper allowing templates to use Less::Pager directly via
Template Toolkit USE directive.

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Update root/include/tag-cloud.tt

**Files:**
- Modify: `root/include/tag-cloud.tt`

**Step 1: Read current file**

Run: `cat root/include/tag-cloud.tt`

**Step 2: Update to use new Tags plugin**

```tt
[% USE tags = Ovid.Tags %]
<aside id="tag-cloud">
<h3>Tags</h3>
<ul id="tags">
[% FOREACH tag IN tags.tags_by_weight %]
    <li><a href="/tags/[% tag %].html" data-weight="[% tags.weight_for_tag(tag) %]">[% tags.name_for_tag(tag) %]</a></li>
[% END %]
</ul>
</aside>
```

**Step 3: Test that rebuild works**

Run: `perl bin/rebuild --notest`
Expected: Build succeeds without errors

**Step 4: Verify tag cloud still renders**

Check: Generated HTML in `index.html` contains tag cloud with proper weights

**Step 5: Commit**

```bash
git add root/include/tag-cloud.tt
git commit -m "refactor: update tag-cloud.tt to use Ovid::Tags

Updates tag cloud template to use new Template::Plugin::Ovid::Tags
instead of calling tag methods on Ovid plugin.

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Update root/include/pager.tt

**Files:**
- Modify: `root/include/pager.tt`

**Step 1: Read current file**

Run: `cat root/include/pager.tt`

**Step 2: Update to use Pager plugin**

Replace calls to `Ovid.prev_post()` and `Ovid.next_post()` with:

```tt
[% USE pager = Pager(type => type) %]
[% prev = pager.prev_post(type, slug) %]
[% next = pager.next_post(type, slug) %]
```

**Step 3: Test that rebuild works**

Run: `perl bin/rebuild --notest`
Expected: Build succeeds without errors

**Step 4: Verify pager still works**

Check: Article pages have prev/next navigation

**Step 5: Commit**

```bash
git add root/include/pager.tt
git commit -m "refactor: update pager.tt to use Pager plugin

Updates pagination template to use Template::Plugin::Pager instead
of delegation through Ovid plugin.

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Find and update templates with direct tag/pager calls

**Files:**
- Find and modify templates using `name_for_tag()` (2 found)
- Find and modify templates using `this_post()` (1 found)

**Step 1: Find templates using name_for_tag**

Run: `git grep -n 'Ovid\.name_for_tag' root/`

**Step 2: Update each template**

Add `[% USE tags = Ovid.Tags %]` and change `Ovid.name_for_tag` to `tags.name_for_tag`

**Step 3: Find templates using this_post**

Run: `git grep -n 'Ovid\.this_post' root/`

**Step 4: Update template**

Add `[% USE pager = Pager %]` and change `Ovid.this_post` to `pager.this_post`

**Step 5: Test that rebuild works**

Run: `perl bin/rebuild --notest`
Expected: Build succeeds without errors

**Step 6: Commit**

```bash
git add root/
git commit -m "refactor: update templates to use new plugins

Updates remaining templates that directly call tag or pager methods
to use the new focused plugins.

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Refactor Template::Plugin::Ovid - Remove tag methods

**Files:**
- Modify: `lib/Template/Plugin/Ovid.pm:19-30` (constructor)
- Modify: `lib/Template/Plugin/Ovid.pm:48-115` (tag methods)
- Modify: `t/ovid_plugin.t`

**Step 1: Update tests to expect tag methods removed**

Add test to verify tag methods are gone:

```perl
subtest 'tag methods removed (moved to Tags plugin)' => sub {
    my $plugin = Template::Plugin::Ovid->new(undef);

    my @removed_methods = qw(
      tags tags_by_weight tags_for_url has_articles_for_tag
      name_for_tag weight_for_tag count_for_tag files_for_tag
      title_for_tag_file
    );

    foreach my $method (@removed_methods) {
        ok !$plugin->can($method), "Should not have method: $method";
    }
};
```

**Step 2: Run test to verify it fails**

Run: `prove -lv t/ovid_plugin.t`
Expected: FAIL - methods still exist

**Step 3: Remove tag methods from Ovid.pm**

Delete these methods:
- `tags()` (lines 48-50)
- `tags_for_url()` (lines 52-54)
- `tags_by_weight()` (lines 58-64)
- `has_articles_for_tag()` (lines 66-68)
- `name_for_tag()` (lines 73-77)
- `weight_for_tag()` (lines 79-94)
- `count_for_tag()` (lines 96-100)
- `files_for_tag()` (lines 102-106)
- `title_for_tag_file()` (lines 111-115)

**Step 4: Remove tagmap from constructor**

Remove from constructor (lines 19-30):
- Remove `Mojo::JSON` import
- Remove `aliased 'Ovid::Template::File::Collection'`
- Remove tagmap file loading
- Remove `tagmap` from blessed hash

New constructor:

```perl
sub new ( $class, $context ) {
    bless {
        _CONTEXT                   => $context,
        footnote_number            => 1,
        footnote_names             => {},
        footnotes                  => [],
        collapsible_section_number => 1,
    }, $class;
}
```

**Step 5: Run test to verify it passes**

Run: `prove -lv t/ovid_plugin.t`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/Template/Plugin/Ovid.pm t/ovid_plugin.t
git commit -m "refactor: remove tag methods from Ovid plugin

Removes all tag-related methods from Template::Plugin::Ovid as they
have been moved to Template::Plugin::Ovid::Tags.

Removed methods: tags, tags_for_url, tags_by_weight,
has_articles_for_tag, name_for_tag, weight_for_tag, count_for_tag,
files_for_tag, title_for_tag_file

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Refactor Template::Plugin::Ovid - Remove pagination methods

**Files:**
- Modify: `lib/Template/Plugin/Ovid.pm:28,256-270` (pager attribute and methods)
- Modify: `t/ovid_plugin.t`

**Step 1: Update tests to expect pagination methods removed**

```perl
subtest 'pagination methods removed (use Pager plugin)' => sub {
    my $plugin = Template::Plugin::Ovid->new(undef);

    my @removed_methods = qw(this_post prev_post next_post is_blog);

    foreach my $method (@removed_methods) {
        ok !$plugin->can($method), "Should not have method: $method";
    }
};
```

**Step 2: Run test to verify it fails**

Run: `prove -lv t/ovid_plugin.t`
Expected: FAIL - methods still exist

**Step 3: Remove pagination methods**

Delete these methods:
- `this_post()` (lines 256-258)
- `prev_post()` (lines 260-262)
- `next_post()` (lines 264-266)
- `is_blog()` (lines 268-270)

**Step 4: Remove pager from constructor**

Remove from constructor:
- Remove `Less::Pager` import
- Remove `pager => Less::Pager->new( type => 'article' )` from blessed hash

**Step 5: Run test to verify it passes**

Run: `prove -lv t/ovid_plugin.t`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/Template/Plugin/Ovid.pm t/ovid_plugin.t
git commit -m "refactor: remove pagination methods from Ovid plugin

Removes pagination delegation methods from Template::Plugin::Ovid.
Templates now use Template::Plugin::Pager directly.

Removed methods: this_post, prev_post, next_post, is_blog

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 8: Remove dead code from Template::Plugin::Ovid

**Files:**
- Modify: `lib/Template/Plugin/Ovid.pm`

**Step 1: Verify methods are truly unused**

Run these searches to confirm no usage:

```bash
git grep '\btags\(' root/ bin/ lib/ | grep -v "Plugin/Ovid"
git grep 'tags_for_url' root/ bin/ lib/ | grep -v "Plugin/Ovid"
git grep 'has_articles_for_tag' root/ bin/ lib/ | grep -v "Plugin/Ovid"
git grep 'count_for_tag' root/ bin/ lib/ | grep -v "Plugin/Ovid"
git grep 'files_for_tag' root/ bin/ lib/ | grep -v "Plugin/Ovid"
git grep 'title_for_tag_file' root/ bin/ lib/ | grep -v "Plugin/Ovid"
git grep 'is_blog' root/ bin/ lib/ | grep -v "Plugin/Ovid"
```

Expected: All return empty (no matches)

**Step 2: Confirm removal is complete**

Dead code was already removed in Tasks 6 and 7.

**Step 3: Update POD documentation**

Remove documentation for deleted methods in `__END__` section.

**Step 4: Run full test suite**

Run: `prove -l t/`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/Template/Plugin/Ovid.pm
git commit -m "docs: update POD for removed methods

Removes documentation for methods that were moved to other plugins
or deleted as dead code.

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 9: Run full site rebuild and verify

**Files:**
- None (verification step)

**Step 1: Run full rebuild with tests**

Run: `perl bin/rebuild`
Expected: Build succeeds, all tests pass

**Step 2: Verify generated HTML**

Check key pages:
- `index.html` - tag cloud renders correctly
- `articles.html` - pagination works
- Any article page - footnotes work, prev/next links work

**Step 3: Run test coverage**

Run: `make coverage` or `cover -test`
Expected: Coverage maintained or improved

**Step 4: Check file sizes**

Run: `wc -l lib/Template/Plugin/Ovid.pm lib/Template/Plugin/Ovid/Tags.pm lib/Template/Plugin/Pager.pm`
Expected: Ovid.pm reduced from ~272 to ~160 lines

**Step 5: Final commit if needed**

If any adjustments were made, commit them.

---

## Task 10: Update documentation and finalize

**Files:**
- Update: `CLAUDE.md` (if needed)
- Update: Design document

**Step 1: Check if CLAUDE.md needs updates**

Review CLAUDE.md for any references to the old plugin structure.

**Step 2: Update design document status**

Mark design document as "Implemented" with link to implementation branch.

**Step 3: Run perltidy on all modified Perl files**

Run: `perltidy --profile=.perltidyrc lib/Template/Plugin/Ovid.pm lib/Template/Plugin/Ovid/Tags.pm lib/Template/Plugin/Pager.pm`

Apply changes: `mv lib/Template/Plugin/Ovid.pm.tdy lib/Template/Plugin/Ovid.pm` (etc.)

**Step 4: Final test run**

Run: `perl bin/rebuild`
Expected: Clean build, all tests pass

**Step 5: Final commit**

```bash
git add .
git commit -m "chore: format code and update docs

Applies perltidy formatting and updates documentation to reflect
completed refactoring.

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Summary

**Total Tasks:** 10
**Estimated Time:** 60-90 minutes
**Test Strategy:** TDD throughout, full regression testing at end

**Key Principles Applied:**
- **TDD:** Write failing tests before implementation
- **YAGNI:** Only implement what's needed, remove dead code
- **DRY:** Extract duplicated logic to focused plugins
- **Frequent Commits:** Each task ends with a commit

**Success Criteria:**
- All tests pass
- Site rebuilds successfully
- Generated HTML identical to before refactoring
- Code coverage maintained
- File count: 3 plugins instead of 1 monolith
- Line count: ~160 (Ovid.pm) vs 272 (original)
