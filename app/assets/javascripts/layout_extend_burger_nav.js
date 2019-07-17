document.addEventListener('DOMContentLoaded',function(){
    const burger_nav = document.querySelector(".burger_nav");
    const btn = burger_nav.querySelector("#burger_nav_extend");
    const main = burger_nav.querySelector("main");

    if (sessionStorage.getItem("burger_nav_big") === "1" && burger_nav.className.indexOf("big") === -1) {
        burger_nav.classList.add("big");
        main.classList.add("big");
    }

    btn.addEventListener("click", evt => {
        if (sessionStorage.getItem("burger_nav_big") === "0" || sessionStorage.getItem("burger_nav_big") == null) {
            sessionStorage.setItem("burger_nav_big", "1");
            burger_nav.classList.add("big");
            main.classList.add("big");
        } else {
            sessionStorage.setItem("burger_nav_big", "0");
            burger_nav.classList.remove("big");
            main.classList.remove("big");
        }
    });

});
