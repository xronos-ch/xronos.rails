document.addEventListener('DOMContentLoaded',function(){
    const left_window_menu = document.querySelector(".left_window_menu");
    const btn = left_window_menu.querySelector("#left_window_nav_general");
    const notch = document.querySelector("#notch");
//    const user_edit_link = notch.querySelector(".user_edit_link");

    btn.addEventListener("click", evt => {
        if (left_window_menu.className.indexOf("active") === -1) {
            left_window_menu.classList.add("active");

            $.ajax({
                url: '/data/activate_left_window',
                type: 'post'
            })

        } else {
            left_window_menu.classList.remove("active");

            $.ajax({
                url: '/data/deactivate_left_window',
                type: 'post'
            })

        }
    });

/*  Not working when user_edit_link not available?
    user_edit_link.addEventListener("click", evt => {
        if (left_window_menu.className.indexOf("active") === -1) {
            left_window_menu.classList.add("active");

            $.ajax({
                url: '/data/activate_left_window',
                type: 'post'
            })

        }
    });
*/
});

