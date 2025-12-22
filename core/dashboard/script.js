// Theme toggle (dark / light)
const root = document.documentElement;
const themeToggle = document.getElementById("themeToggle");

let isLight = false;

function updateTheme() {
    if(isLight) {
        root.setAttribute("data-theme", "light");
        themeToggle.querySelector(".theme-toggle__icon").textContent = "☀️";
    } else {
        root.removeAttribute("data-theme");
        themeToggle.querySelector(".theme-toggle__icon").textContent = "🌙";
    }
}

themeToggle.addEventListener("click", () => {
    isLight = !isLight;
    updateTheme();
});

updateTheme();

// Sidebar nav active state
const navItems = document.querySelectorAll(".nav-item");
navItems.forEach((btn) => {
    btn.addEventListener("click", () => {
        navItems.forEach((b) => b.classList.remove("nav-item--active"));
        btn.classList.add("nav-item--active");
    });
});

// Filter projects by status
const statusFilter = document.getElementById("statusFilter");
const rows = document.querySelectorAll(".table__row");

statusFilter.addEventListener("change", () => {
    const value = statusFilter.value;
    rows.forEach((row) => {
        const status = row.getAttribute("data-status");
        const show = value === "all" || status === value;
        row.style.display = show ? "grid" : "none";
    });
});