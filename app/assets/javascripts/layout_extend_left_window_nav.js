document.addEventListener('DOMContentLoaded',function(){
    const left_window_nav = document.querySelector(".left_window_nav");
    const btn = left_window_nav.querySelector("#left_window_nav_extend");
    const main = left_window_nav.querySelector("main");

    if (sessionStorage.getItem("left_window_nav_big") === "1" && left_window_nav.className.indexOf("big") === -1) {
        left_window_nav.classList.add("big");
        main.classList.add("big");
    }

    btn.addEventListener("click", evt => {
        if (sessionStorage.getItem("left_window_nav_big") === "0" || sessionStorage.getItem("left_window_nav_big") == null) {
            sessionStorage.setItem("left_window_nav_big", "1");
            left_window_nav.classList.add("big");
            main.classList.add("big");
        } else {
            sessionStorage.setItem("left_window_nav_big", "0");
            left_window_nav.classList.remove("big");
            main.classList.remove("big");
        }
    });

});
