document.addEventListener('DOMContentLoaded',function(){
    const right_window_menu = document.querySelector(".right_window_menu");
    const btn = right_window_menu.querySelector("#right_window_nav_general");
    btn.addEventListener("click", evt => {
        if (right_window_menu.className.indexOf("active") === -1) {
            right_window_menu.classList.add("active");
        } else {
            right_window_menu.classList.remove("active");
        }
    });
});
