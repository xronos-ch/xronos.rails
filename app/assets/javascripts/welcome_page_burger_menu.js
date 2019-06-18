document.addEventListener('DOMContentLoaded',function(){
	const burger_menu = document.querySelector(".burger_menu");
	const btn = burger_menu.querySelector(".burger_nav-tgl");
	btn.addEventListener("click", evt => {
		if (burger_menu.className.indexOf("active") === -1) {
			burger_menu.classList.add("active");
		} else {
			burger_menu.classList.remove("active");
		}
	});
});
