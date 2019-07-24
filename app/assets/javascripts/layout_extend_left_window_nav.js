document.addEventListener('DOMContentLoaded',function(){
    const left_window_menu = document.querySelector(".left_window_menu");
    const left_window_nav = left_window_menu.querySelector(".left_window_nav");
    const btn = left_window_nav.querySelector("#left_window_nav_extend");
    const main = left_window_nav.querySelector("main");

    btn.addEventListener("click", evt => {
        if (left_window_nav.className.indexOf("big") === -1) {
            left_window_nav.classList.add("big");
            main.classList.add("big");

            $.ajax({
                url: '/data/extend_left_window',
                type: 'post'
            })

        } else {
            left_window_nav.classList.remove("big");
            main.classList.remove("big");

            $.ajax({
                url: '/data/reduce_left_window',
                type: 'post'
            })

        }
    });
});
