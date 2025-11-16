# Quickstart Guide: Collapsible Sections

**Feature**: 004-collapsible-sections  
**For**: Content Authors  
**Updated**: 2025-11-16

## What Are Collapsible Sections?

Collapsible sections let you hide supplementary content that readers can reveal by clicking. This keeps your articles focused while still providing detailed information for interested readers.

**Use Cases**:
- Implementation details that might distract from the main narrative
- Code examples or technical deep-dives
- Background information or historical context
- FAQ-style content
- Tangential but relevant information

## Basic Usage

### Template Toolkit Syntax

```tt
[% USE Ovid %]

[% Ovid.collapse(
    "Click to see the implementation",
    "Here's the detailed implementation code..."
) %]
```

### Parameters

1. **Short Description** (required): Summary text that's always visible
2. **Full Content** (required): Detailed content shown when expanded

Both parameters must be non-empty.

## Simple Example

```tt
[% USE Ovid %]

<article>
    <h1>Understanding Memoization</h1>
    
    <p>Memoization is an optimization technique that stores
    the results of expensive function calls.</p>
    
    [% Ovid.collapse(
        "Click for a simple example",
        "Here's a Fibonacci function with memoization: ~~~perl
my %cache;
sub fib {
    my \$n = shift;
    return \$cache{\$n} if exists \$cache{\$n};
    return \$cache{\$n} = \$n < 2 ? \$n : fib(\$n-1) + fib(\$n-2);
}
~~~"
    ) %]
    
    <p>This technique can dramatically improve performance...</p>
</article>
```

## Using Blogdown Syntax

The full content parameter supports **blogdown** formatting (Markdown):

### Code Blocks

```tt
[% Ovid.collapse(
    "Example Code",
    "~~~perl
use v5.40;
say 'Hello, World!';
~~~"
) %]
```

**Supported Languages**: perl, javascript, python, sql, bash, etc.

### Lists and Formatting

```tt
[% Ovid.collapse(
    "Key Benefits",
    "The main advantages are:

- **Improved readability**: Keep main content focused
- **Progressive disclosure**: Let readers choose their depth
- **Better organization**: Group related details together

This helps both new and experienced readers."
) %]
```

### External Links

```tt
[% Ovid.collapse(
    "Further Reading",
    "For more information, see [the Wikipedia article](https://en.wikipedia.org/wiki/Memoization).

The link automatically opens in a new tab with an external link icon."
) %]
```

## Multiple Sections

You can add as many collapsible sections as needed:

```tt
[% Ovid.collapse("Section 1", "Content for section 1") %]

<p>Some regular content between sections.</p>

[% Ovid.collapse("Section 2", "Content for section 2") %]

[% Ovid.collapse("Section 3", "Content for section 3") %]
```

Each section operates independently - opening one doesn't close others.

## Combining with Footnotes

Collapsible sections work with footnotes:

```tt
[% Ovid.collapse(
    "Implementation Details",
    "This approach was first described by Donald Knuth.[% Ovid.add_note('See The Art of Computer Programming, Vol 1') %]"
) %]
```

## What Readers See

### With JavaScript Enabled (Default)

1. **Initially**: Collapsed section showing icon + short description
2. **On Click**: Content expands to reveal full details
3. **On Second Click**: Content collapses again

**Icon Changes**:
- Collapsed: Chevron-down (▼)
- Expanded: Chevron-up (▲)

### Without JavaScript

Both the short description and full content are visible:
- Short description shown in bold
- Full content indented for visual hierarchy
- No interactive behavior (all content always visible)

This ensures accessibility for all users.

## Best Practices

### Writing Good Short Descriptions

✅ **Good**: "Click to see the implementation"  
❌ **Bad**: "Click here"

✅ **Good**: "Example: Fibonacci with memoization"  
❌ **Bad**: "Example"

**Tip**: The short description should summarize what the content contains.

### When to Use Collapsible Sections

**Use for**:
- Optional details that complement the main text
- Code examples illustrating a concept
- Supplementary resources or links
- Step-by-step instructions

**Don't use for**:
- Critical information all readers need
- Primary narrative flow
- First mention of key concepts
- Content that's referenced later in the article

### Content Length Guidelines

- **Short Description**: 1-2 sentences (keep it scannable)
- **Full Content**: Any length, but consider multiple sections for very long content

## Error Messages

### Empty Parameters

```tt
[% Ovid.collapse("", "Content") %]
```

**Error**: `collapse() requires short_description parameter`

### Whitespace Only

```tt
[% Ovid.collapse("Summary", "   ") %]
```

**Error**: `collapse() requires full_content parameter`

### Missing Parameter

```tt
[% Ovid.collapse("Summary") %]
```

**Error**: Template Toolkit compile error (wrong number of arguments)

**Fix**: Always provide both parameters with non-empty content.

## Accessibility Features

Collapsible sections are fully accessible:

- **Screen Readers**: Announce collapsed/expanded state
- **Keyboard Navigation**: 
  - `Tab` to focus the trigger
  - `Enter` or `Space` to expand/collapse
- **No JavaScript Required**: Content still accessible
- **Print Friendly**: All content visible when printed

## Styling

Collapsible sections automatically match your site's design:

- Full width of content area
- Responsive on mobile devices
- Consistent colors and spacing
- Smooth hover effects

No custom styling needed.

## Advanced: Nesting Content

### With Other Template Features

You can nest other Template Toolkit features inside collapsible content:

```tt
[% Ovid.collapse(
    "Watch the Video Tutorial",
    "[% Ovid.youtube('dQw4w9WgXcQ') %]
    
This video explains the concept in detail."
) %]
```

### Complex Blogdown

```tt
[% Ovid.collapse(
    "Comparison Table",
    "| Feature | Approach A | Approach B |
|---------|-----------|------------|
| Speed | Fast | Slow |
| Memory | Low | High |
| Complexity | Simple | Complex |"
) %]
```

Tables are formatted automatically.

## Troubleshooting

### Content Not Appearing

**Problem**: Content doesn't show when clicked

**Check**:
1. Is JavaScript enabled in your browser?
2. Is `collapsible.js` included in the page?
3. Are there console errors?

**Test**: Disable JavaScript - content should be visible in noscript mode.

### Styling Issues

**Problem**: Section doesn't look right

**Check**:
1. Is `collapsible.css` included in the page?
2. Are there CSS conflicts with custom styles?
3. Does the page validate as HTML5?

### Build Errors

**Problem**: Site build fails with error message

**Check**:
1. Are both parameters non-empty?
2. Is the syntax correct (`[% Ovid.collapse(...) %]`)?
3. Are quote marks balanced?

**Tip**: Error messages tell you exactly which parameter is invalid.

## Complete Example

Here's a full article using collapsible sections:

```tt
[%
    title            = 'Understanding Recursion';
    type             = 'article';
    slug             = 'understanding-recursion';
    include_comments = 1;
    date             = '2025-11-16';
    USE Ovid;
%]
[% WRAPPER include/wrapper.html blogdown=1 -%]

# Understanding Recursion

Recursion is a powerful programming technique where a function calls itself.

[% Ovid.collapse(
    "What makes a function recursive?",
    "A recursive function has two key components:

1. **Base case**: A condition that stops the recursion
2. **Recursive case**: The function calling itself with a simpler input

Without a base case, the function would recurse infinitely and crash."
) %]

## Practical Example

Let's look at calculating factorials.

[% Ovid.collapse(
    "Factorial Implementation",
    "~~~perl
use v5.40;

sub factorial(\$n) {
    return 1 if \$n <= 1;  # Base case
    return \$n * factorial(\$n - 1);  # Recursive case
}

say factorial(5);  # Prints 120
~~~

This function:
- Returns 1 for 0 or 1 (base case)
- Multiplies n by factorial(n-1) for larger values"
) %]

## Performance Considerations

Recursion can be inefficient for some problems.

[% Ovid.collapse(
    "Why recursion can be slow",
    "Each recursive call adds a frame to the call stack, consuming memory.
    
For problems like Fibonacci, naive recursion recalculates the same values
many times. This is where memoization helps.[% Ovid.add_note('We covered memoization in a previous article') %]

**Alternatives**:
- Iterative solutions (using loops)
- Tail recursion optimization
- Dynamic programming"
) %]

## Summary

Recursion is elegant but should be used thoughtfully. Consider the
trade-offs between clarity and performance for your specific use case.

[% END %]
```

## Quick Reference

```tt
# Basic usage
[% Ovid.collapse("Summary", "Details") %]

# With code
[% Ovid.collapse("Code Example", "~~~perl\ncode here\n~~~") %]

# With Markdown
[% Ovid.collapse("Info", "**Bold** and *italic* text") %]

# Multiple sections
[% Ovid.collapse("First", "Content 1") %]
[% Ovid.collapse("Second", "Content 2") %]
```

## Need Help?

- Review this guide
- Check error messages (they're descriptive)
- Verify both parameters are non-empty
- Test with JavaScript disabled to see noscript fallback

## Summary

Collapsible sections help you:
- Keep articles focused and scannable
- Provide optional details for interested readers
- Maintain accessibility for all users
- Organize content hierarchically

Use them to enhance your articles without overwhelming readers!
