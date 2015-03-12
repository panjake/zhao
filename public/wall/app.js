var app = document.getElementsByClassName('scarcity-offer');
for(var i in app) {		
	app[i].onclick = function(e) {				
		if($(this).data('installed') == '1') {					
			$('#dialog').find('h2').html($(this).find('h2').html());
			$('#dialog').find('p#draft').html($(this).find('.draft').html());
			$('#dialog').find('p#icon').html($(this).find('div.icon').html());
			$('#dialog').find('a#download').attr('href', $(this).data('goal'));
			$.mobile.changePage( "#dialog", { role: "dialog" } );		
		}		
		//location.href = this.getAttribute('goal');
	};
}