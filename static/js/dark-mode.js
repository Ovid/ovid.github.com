document.addEventListener('DOMContentLoaded', function() {
    const toggle = document.getElementById('theme-toggle');
    const icon = toggle.querySelector('i');
    const html = document.documentElement;
    
    // Sync icon with current state (set by inline script in header)
    if (html.getAttribute('data-theme') === 'dark') {
        icon.classList.remove('fa-moon-o');
        icon.classList.add('fa-sun-o');
    }
    
    toggle.addEventListener('click', function() {
        const theme = html.getAttribute('data-theme');
        if (theme === 'dark') {
            html.removeAttribute('data-theme');
            localStorage.setItem('theme', 'light');
            icon.classList.remove('fa-sun-o');
            icon.classList.add('fa-moon-o');
        } else {
            html.setAttribute('data-theme', 'dark');
            localStorage.setItem('theme', 'dark');
            icon.classList.remove('fa-moon-o');
            icon.classList.add('fa-sun-o');
        }
    });
});
