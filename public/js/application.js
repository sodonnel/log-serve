// Goto Date form
jQuery(function($) {
    $("#gotoDate").submit(function( event ) {
	$.post("/gotodate", $("#gotoDate").serialize(), function(response) {
	    eval(response);
	}).fail(function() {
	    alert( "Failed to goto the date - server error" );
	});
	return false;
    });
});


function load_log_lines() {
    if ($('#container').attr("data-infinite-scroll-status")  != 'ready') {
	return;
    }
    $('#container').attr("data-infinite-scroll-status", "loading");
    var position = $('#container').attr("data-infinite-scroll-position")
    var filekey  = $('#container').attr("data-filekey")
    $.get("/loglines/"+filekey+"/"+position, function(response) {
	eval(response)
//	$('#container').attr('data-infinite-scroll-status', 'ready');
    }).fail(function() {
	alert( "Failed to retrieve logs - server error" );
	$('#container').attr('data-infinite-scroll-status', 'ready');
    });
}


function reset_position(new_position) {
    // This method will set the data-infinite-scroll-position, clear the loglines
    // and then call load_log_lines to load new logs
    $('#container').attr('data-infinite-scroll-position', new_position);
    $('#code').empty();
    load_log_lines();
    
}


jQuery(function($) {
    $(document).ready(function() {
	load_log_lines();
    })
});


// Infinite scroll on the articles and subsciption pages
// To trigger the scroll earlier, make the 3000 below bigger.
jQuery(function($) {
  $(window).scroll(function() {
    if ( ($(window).scrollTop() >= $(document).height() - $(window).height() - 3000)
         && ($('#container').attr("data-infinite-scroll-status") == 'ready') ) {
	load_log_lines();
    }
  })
});
