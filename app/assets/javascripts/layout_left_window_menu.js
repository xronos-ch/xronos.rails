document.addEventListener('DOMContentLoaded',function(){
	const left_window_menu = document.querySelector(".left_window_menu");
	const btn = left_window_menu.querySelector(".left_window_nav-tgl");
	btn.addEventListener("click", evt => {
		if (left_window_menu.className.indexOf("active") === -1) {
			left_window_menu.classList.add("active");
		} else {
			left_window_menu.classList.remove("active");
		}
	});
});
