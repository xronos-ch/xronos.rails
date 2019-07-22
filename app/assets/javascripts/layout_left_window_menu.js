document.addEventListener('DOMContentLoaded',function(){
	const left_window_menu = document.querySelector(".left_window_menu");
	const btn = left_window_menu.querySelector("#left_window_nav_general");
    const notch = document.querySelector("#notch");
    const user_edit_link = notch.querySelector(".user_edit_link");

    if (sessionStorage.getItem("left_window_menu_active") === "1" && left_window_menu.className.indexOf("active") === -1) {
        left_window_menu.classList.add("active");
    }

    btn.addEventListener("click", evt => {
        if (sessionStorage.getItem("left_window_menu_active") === "0" || sessionStorage.getItem("left_window_menu_active") == null) {
            sessionStorage.setItem("left_window_menu_active", "1");
            left_window_menu.classList.add("active");
        } else {
            sessionStorage.setItem("left_window_menu_active", "0");
            left_window_menu.classList.remove("active");
        }
    });

    user_edit_link.addEventListener("click", evt => {
        if (sessionStorage.getItem("left_window_menu_active") === "0" || sessionStorage.getItem("left_window_menu_active") == null) {
            sessionStorage.setItem("left_window_menu_active", "1");
        }
    });

});
