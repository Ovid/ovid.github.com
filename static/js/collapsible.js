/**
 * Collapsible Sections JavaScript
 * 
 * Feature: 004-collapsible-sections
 * Purpose: Client-side expand/collapse interaction for collapsible sections
 * 
 * Architecture: Progressive Enhancement
 * - Content is accessible without JavaScript (see noscript fallback in HTML)
 * - JavaScript adds interactive toggle behavior when enabled
 * 
 * Dependencies: None (vanilla JavaScript, no external libraries)
 * Browser Support: Modern browsers (Chrome, Firefox, Safari, Edge)
 * 
 * Key Features:
 * - Toggle collapse/expand on trigger click
 * - Keyboard accessibility (Enter/Space keys)
 * - ARIA attribute updates (aria-expanded)
 * - Icon rotation animation
 * - Independent operation of multiple sections on same page
 * 
 * Implementation Notes:
 * - Each section operates independently (no shared state)
 * - Event handlers use event.target to find specific section
 * - aria-controls attribute links trigger to content element
 */

/* ========================================
   Module Initialization
   ======================================== */

/**
 * Initialize all collapsible sections when DOM is ready
 */
document.addEventListener('DOMContentLoaded', function() {
    // Add js-enabled class to enable JavaScript-specific styles
    // This hides content by default and removes no-JS indentation
    document.documentElement.classList.add('js-enabled');
    
    // Find all collapsible trigger elements
    const triggers = document.querySelectorAll('.collapsible-trigger');
    
    // Attach event listeners to each trigger individually
    triggers.forEach(function(trigger) {
        // Click event listener
        trigger.addEventListener('click', function(event) {
            event.preventDefault();
            toggleCollapsible(trigger);
        });
        
        // Keyboard event listener (Enter and Space keys)
        trigger.addEventListener('keydown', function(event) {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                toggleCollapsible(trigger);
            }
        });
    });
});

/* ========================================
   Event Handlers
   ======================================== */

/**
 * Toggle a specific collapsible section
 * @param {HTMLElement} trigger - The trigger element that was clicked
 */
function toggleCollapsible(trigger) {
    // Get the content element ID from aria-controls
    const contentId = trigger.getAttribute('aria-controls');
    
    if (!contentId) {
        console.warn('Collapsible trigger missing aria-controls attribute', trigger);
        return;
    }
    
    // Find the specific content element
    const content = document.getElementById(contentId);
    
    if (!content) {
        console.warn('Collapsible content element not found for ID:', contentId);
        return;
    }
    
    // Check current state
    const isExpanded = trigger.getAttribute('aria-expanded') === 'true';
    
    // Toggle ARIA attribute
    trigger.setAttribute('aria-expanded', !isExpanded);
    
    // Toggle expanded class on content
    content.classList.toggle('expanded');
    
    // Note: Icon rotation is handled by CSS via aria-expanded attribute
    // See collapsible.css: .collapsible-trigger[aria-expanded="true"] .collapsible-icon
    // No need to manually toggle icon classes here
}

/* ========================================
   Independence Verification
   ======================================== */

/**
 * CRITICAL: Each section must operate independently
 * - Use trigger.getAttribute('aria-controls') to find specific content
 * - Never use global selectors like querySelectorAll('.collapsible-content')
 * - Verify multiple sections don't interfere with each other
 */
