# Quickstart Guide: Footnote NoScript Fallback

**Feature**: 002-footnote-noscript-fallback  
**Date**: 2025-11-09  
**Audience**: Developers implementing or testing this feature

---

## What This Feature Does

Fixes critical accessibility bug where footnotes are unreadable when JavaScript is disabled. Implements dual rendering:

- **JavaScript ON** (default): Footnotes appear in modal popups (current behavior, unchanged)
- **JavaScript OFF**: Footnotes appear as anchor-linked list at article end (restored old behavior)

**Problem Solved**: Users with JavaScript disabled currently see a blocking modal overlay with no way to dismiss it, making the entire page unreadable.

---

## Quick Testing

### Test JavaScript-Enabled Mode (Current Behavior)

1. **Build the site**:
   ```bash
   source ~/.bash_profile  # Activate Perl environment
   perl bin/rebuild
   ```

2. **Start local server**:
   ```bash
   http_this
   ```

3. **Open an article with footnotes** (e.g., http://127.0.0.1:7007/articles/building-an-iphone-app-with-chatgpt.html)

4. **Click a footnote clipboard icon** → Modal dialog should appear

5. **Close the modal**:
   - Press `ESC` key, OR
   - Click the `×` button, OR
   - Click outside the modal

**Expected**: Modal opens and closes correctly (existing behavior)

---

### Test JavaScript-Disabled Mode (New Behavior)

1. **Disable JavaScript in your browser**:
   
   **Chrome**:
   - Open DevTools (Cmd+Option+I on Mac)
   - Cmd+Shift+P → "JavaScript" → "Disable JavaScript"
   - Refresh page
   
   **Firefox**:
   - Type `about:config` in address bar
   - Search for `javascript.enabled`
   - Toggle to `false`
   - Refresh page
   
   **Safari**:
   - Develop menu → Disable JavaScript
   - (If Develop menu not visible: Preferences → Advanced → Show Develop menu)

2. **Open the same article**

3. **Verify no overlay blocking content** ✅

4. **Scroll to end of article** → "Footnotes" section should be visible ✅

5. **Click a footnote clipboard icon in article text** → Browser scrolls to footnote ✅

6. **Click "↩ Return to text" link** → Browser scrolls back to reference ✅

**Expected**: Full article readability with anchor-based footnote navigation

---

## Development Workflow

### 1. Setup Environment

```bash
# Activate Perl 5.40+ environment (required before all work)
source ~/.bash_profile

# Verify Perl version
perl -v  # Should show 5.40 or higher

# Install dependencies (if not already done)
cpanm --installdeps . --with-configure --with-develop --with-all-features
```

### 2. Run Existing Tests (Baseline)

```bash
# Run all tests
prove -l t/

# Run only footnote plugin tests
prove -lv t/ovid_plugin.t

# Run with coverage
cover -test

# View coverage report
open cover_db/coverage.html
```

**Expected**: All tests pass before making changes (establish baseline)

### 3. Make Code Changes

**Files to modify**:

1. **`lib/Template/Plugin/Ovid.pm`** - Modify `add_note()` method:
   - Generate noscript anchor link in addition to JS dialog trigger
   - Store raw `content` field in footnote hash
   - Example:
     ```perl
     sub add_note ( $self, $note ) {
         my $number = $self->{footnote_number}++;
         
         # JavaScript dialog HTML (existing)
         my $dialog = qq{<span class="open-dialog" id="open-dialog-$number">📋</span>};
         
         # NoScript anchor link (NEW)
         my $noscript = qq{<noscript><a href="#footnote-$number" id="footnote-$number-return">📋</a></noscript>};
         
         # Store both in footnotes array
         push $self->{footnotes}->@* => {
             number  => $number,
             body    => $dialog_body,  # Full dialog HTML
             content => $note,          # Raw content for noscript
         };
         
         return $dialog . $noscript;
     }
     ```

2. **`root/include/footer.tt`** - Add noscript section:
   ```tt2
   [% IF Ovid.has_footnotes %]
     <!-- JavaScript mode (existing) -->
     <div class="dialog-overlay" tabindex="-1"></div>
     [% footnotes = Ovid.get_footnotes %]
     <!-- ... existing dialog rendering ... -->
     
     <!-- NoScript mode (NEW) -->
     <noscript>
       <aside class="footnotes" id="footnotes-section" aria-label="Footnotes">
         <h2>Footnotes</h2>
         <ol>
           [% FOR fn IN footnotes %]
           <li id="footnote-[% fn.number %]">
             [% fn.content %]
             <a href="#footnote-[% fn.number %]-return">↩ Return to text</a>
           </li>
           [% END %]
         </ol>
       </aside>
     </noscript>
   [% END %]
   ```

3. **`t/ovid_plugin.t`** - Add tests for both modes (see Testing section below)

### 4. Run Tests After Changes

```bash
# Run tests
prove -lv t/ovid_plugin.t

# Check coverage
cover -test
cover -report html -outputdir coverage-report
open coverage-report/index.html
```

**Expected**: All tests pass, coverage ≥ 90%

### 5. Manual Testing

```bash
# Rebuild site with changes
perl bin/rebuild

# Start server
http_this

# Test both JS enabled and disabled modes (see Quick Testing above)
```

---

## Testing Implementation

### Unit Tests to Add

**File**: `t/ovid_plugin.t`

```perl
use Test::Most;
use Template::Plugin::Ovid;

subtest 'add_note generates dual HTML output' => sub {
    my $context = mock_template_context();
    my $plugin = Template::Plugin::Ovid->new($context);
    
    my $html = $plugin->add_note('Test footnote content');
    
    # Test JavaScript mode HTML
    like $html, qr/class="open-dialog"/, 'Contains dialog trigger';
    like $html, qr/id="open-dialog-1"/, 'Has correct dialog ID';
    
    # Test NoScript mode HTML (NEW)
    like $html, qr/<noscript>/, 'Contains noscript tag';
    like $html, qr/href="#footnote-1"/, 'Has footnote anchor link';
    like $html, qr/id="footnote-1-return"/, 'Has return anchor ID';
    
    # Test stored data structure
    my $footnotes = $plugin->get_footnotes();
    is scalar @$footnotes, 1, 'One footnote stored';
    is $footnotes->[0]{number}, 1, 'Footnote number is 1';
    is $footnotes->[0]{content}, 'Test footnote content', 'Content stored correctly';
    like $footnotes->[0]{body}, qr/dialog-1/, 'Dialog body has correct ID';
};

subtest 'add_note with HTML content' => sub {
    my $plugin = Template::Plugin::Ovid->new(mock_template_context());
    
    $plugin->add_note('Footnote with <em>emphasis</em> and <a href="#">link</a>');
    
    my $footnotes = $plugin->get_footnotes();
    like $footnotes->[0]{content}, qr/<em>emphasis<\/em>/, 'HTML preserved';
    like $footnotes->[0]{content}, qr/<a href="#">link<\/a>/, 'Links preserved';
};

subtest 'add_note sequential numbering' => sub {
    my $plugin = Template::Plugin::Ovid->new(mock_template_context());
    
    $plugin->add_note('First');
    $plugin->add_note('Second');
    $plugin->add_note('Third');
    
    my $footnotes = $plugin->get_footnotes();
    is $footnotes->[0]{number}, 1, 'First footnote is 1';
    is $footnotes->[1]{number}, 2, 'Second footnote is 2';
    is $footnotes->[2]{number}, 3, 'Third footnote is 3';
};

done_testing;
```

### Integration Tests (Optional)

```perl
subtest 'Built HTML contains both JS and noscript footnotes' => sub {
    # Build a test article
    system('perl bin/rebuild') == 0 or die "Build failed";
    
    # Read generated HTML
    my $html = path('articles/test-article.html')->slurp;
    
    # Verify JavaScript mode
    like $html, qr/class="dialog-overlay"/, 'Contains dialog overlay';
    like $html, qr/class="dialog"/, 'Contains dialog element';
    like $html, qr/Dialog\.js/, 'Contains Dialog.js script';
    
    # Verify NoScript mode
    like $html, qr/<noscript>/, 'Contains noscript tag';
    like $html, qr/<aside class="footnotes"/, 'Contains footnotes aside';
    like $html, qr/<ol>.*<\/ol>/s, 'Contains ordered list';
    like $html, qr/id="footnote-1"/, 'Contains footnote ID';
    like $html, qr/href="#footnote-1-return"/, 'Contains return link';
};
```

---

## Debugging Tips

### Problem: Tests Failing

```bash
# Run tests with verbose output
prove -lv t/ovid_plugin.t

# Check for syntax errors
perl -c lib/Template/Plugin/Ovid.pm

# Run perltidy to fix formatting
perltidy --profile=.perltidyrc lib/Template/Plugin/Ovid.pm
```

### Problem: Site Won't Build

```bash
# Check for Template Toolkit errors
perl bin/rebuild 2>&1 | grep -i error

# Check specific template
perl -MTemplate -e 'Template->new->process("root/include/footer.tt") or die'
```

### Problem: Noscript Section Not Appearing

1. **Check browser is actually disabling JS**:
   - View page source (`Cmd+Option+U`)
   - Look for `<noscript>` content
   - If visible in source but not rendered, JS is still enabled

2. **Check footer template syntax**:
   ```tt2
   [% IF Ovid.has_footnotes %]
     <!-- Should see noscript tag here -->
   [% END %]
   ```

3. **Check footnote data structure**:
   ```perl
   # In Ovid.pm, add debug output
   use Data::Dumper;
   warn Dumper($self->{footnotes});
   ```

### Problem: Anchor Links Not Working

1. **Check ID naming**:
   - Article reference: `id="footnote-N-return"`
   - Footer footnote: `id="footnote-N"`
   - Link href: `href="#footnote-N"` and `href="#footnote-N-return"`

2. **Check IDs are unique**:
   ```bash
   # Search for duplicate IDs in generated HTML
   grep -o 'id="footnote-[0-9]*' articles/test-article.html | sort | uniq -d
   ```

---

## File Locations Reference

```text
lib/
└── Template/
    └── Plugin/
        └── Ovid.pm              # Modify: add_note() method

root/
└── include/
    └── footer.tt                # Modify: add noscript section

t/
└── ovid_plugin.t                # Modify: add test cases

static/
└── css/
    └── main.css                 # Optional: add .footnotes styles

docs/
└── specs/
    └── 002-footnote-noscript-fallback/
        ├── spec.md              # Feature specification
        ├── plan.md              # Implementation plan (this doc's parent)
        ├── research.md          # Research findings
        ├── data-model.md        # Data structures
        ├── quickstart.md        # This file
        └── contracts/
            ├── add_note_method.md
            ├── footer_footnote_rendering.md
            └── css_display_rules.md
```

---

## Common Commands

```bash
# Environment setup
source ~/.bash_profile

# Build site
perl bin/rebuild

# Run tests
prove -l t/

# Run specific test file
prove -lv t/ovid_plugin.t

# Coverage report
cover -test
open cover_db/coverage.html

# Format code
perltidy --profile=.perltidyrc lib/**/*.pm

# Local dev server
http_this  # Access at http://127.0.0.1:7007/

# Validate HTML
# (Use online validator: https://validator.w3.org/nu/)
```

---

## Success Checklist

Before considering this feature complete, verify:

- [ ] ✅ Tests pass with ≥90% coverage
- [ ] ✅ JavaScript-enabled users see modal dialogs (unchanged)
- [ ] ✅ JavaScript-disabled users see footnote section at article end
- [ ] ✅ No modal overlay blocks content when JS disabled
- [ ] ✅ Anchor navigation works both directions (text ↔ footnote)
- [ ] ✅ Generated HTML validates as HTML5
- [ ] ✅ Screen reader announces footnotes correctly (test with VoiceOver/NVDA)
- [ ] ✅ Existing articles render correctly in both modes
- [ ] ✅ No performance regression (build time <2 minutes)
- [ ] ✅ All Perl code formatted with perltidy
- [ ] ✅ POD documentation updated

---

## Next Steps

After implementation:

1. **Create pull request** with changes
2. **Deploy to staging** environment
3. **Test with screen readers** (VoiceOver on Mac, NVDA on Windows)
4. **Test on multiple browsers** (Chrome, Firefox, Safari, Edge)
5. **Deploy to production**
6. **Monitor for issues** in first 24 hours

---

## Resources

- **Feature Spec**: `specs/002-footnote-noscript-fallback/spec.md`
- **Implementation Plan**: `specs/002-footnote-noscript-fallback/plan.md`
- **Research Findings**: `specs/002-footnote-noscript-fallback/research.md`
- **Data Model**: `specs/002-footnote-noscript-fallback/data-model.md`
- **Contracts**: `specs/002-footnote-noscript-fallback/contracts/`
- **Constitution**: `.specify/memory/constitution.md`
- **Copilot Instructions**: `.github/copilot-instructions.md`

---

**Status**: Ready for Implementation  
**Estimated Time**: 2-4 hours (coding + testing)  
**Complexity**: Low (straightforward template + module changes)
