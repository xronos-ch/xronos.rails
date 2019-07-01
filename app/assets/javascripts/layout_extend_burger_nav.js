document.addEventListener('DOMContentLoaded',function(){
    const burger_nav = document.querySelector(".burger_nav");
    const btn = burger_nav.querySelector("#burger_nav_extend");
    const main = burger_nav.querySelector("main");
    btn.addEventListener("click", evt => {
        if (burger_nav.className.indexOf("big") === -1) {
            burger_nav.classList.add("big");
            main.classList.add("big");
        } else {
            burger_nav.classList.remove("big");
            main.classList.remove("big");
        }
    });
});
