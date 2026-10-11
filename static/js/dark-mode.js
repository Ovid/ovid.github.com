document.addEventListener('DOMContentLoaded', function() {
    const toggle = document.getElementById('theme-toggle');
    const icon = toggle.querySelector('i');
    const html = document.documentElement;

    // Icon and aria-pressed follow data-theme (first set by inline script in header)
    function sync() {
        const dark = html.getAttribute('data-theme') === 'dark';
        toggle.setAttribute('aria-pressed', dark ? 'true' : 'false');
        icon.classList.toggle('fa-sun-o', dark);
        icon.classList.toggle('fa-moon-o', !dark);
    }
    sync();

    toggle.addEventListener('click', function() {
        const theme = html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
        if (theme === 'dark') html.setAttribute('data-theme', 'dark');
        else html.removeAttribute('data-theme');
        sync();
        // Throws when site data is blocked; the switch still works for this page.
        try { localStorage.setItem('theme', theme); } catch (e) {}
    });
});
