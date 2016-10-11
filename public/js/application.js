// Goto Date form
jQuery(function($) {
    $("#gotoDate").submit(function( event ) {
	var filekey  = $('#container').attr("data-filekey")
	$.post("/gotodate/"+filekey, $("#gotoDate").serialize(), function(response) {
	    eval(response);
	}).fail(function() {
	    alert( "Failed to goto the date - server error" );
	});
	return false;
    });
});

jQuery(function($) {
    $("#endButton").click(function( event ) {
	var filekey = $('#container').attr("data-filekey")
	$.get("/file/"+filekey+"/position/end", function(response) {
	    eval(response);
	}).fail(function() {
	    alert( "Failed to goto the end of the file - server error" );
	});
	return false;
    });
});


function load_log_lines(forwards) {
    var statusAttr = forwards ? "data-infinite-scroll-status" : "data-infinite-scroll-earlier-status"
    if ($('#container').attr(statusAttr)  != 'ready' ) {
	return;
    }

    $('#container').attr(statusAttr, "loading");
    var filekey  = $('#container').attr("data-filekey")
    var position = $('#container').attr(forwards ? "data-infinite-scroll-position" : "data-infinite-scroll-earlier-position")
    
    var url = forwards ? "/loglines/" : "/viewer/previouslines/"
    $.get(url+filekey+"/"+position, function(response) {
	eval(response)
    }).fail(function() {
	alert( "Failed to retrieve logs - server error" );
	$('#container').attr(statusAttr, 'ready');
    });
}


function reset_position(new_position) {
    // This method will set the data-infinite-scroll-position, clear the loglines
    // and then call load_log_lines to load new logs
    $('#container').attr('data-infinite-scroll-position', new_position);
    $('#container').attr('data-infinite-scroll-earlier-position', new_position);
    $('#container').attr('data-infinite-scroll-status', 'ready');
    $('#container').attr('data-infinite-scroll-earlier-status', 'ready');
    $('#code').empty();
    // Pre load some lines ahead and behind
    load_log_lines(true);
    load_log_lines(false);
}


jQuery(function($) {
    $(document).ready(function() {
	load_log_lines(true);
    })
});


// Infinite scroll on the articles and subsciption pages
// To trigger the scroll earlier, make the 3000 below bigger.
//jQuery(function($) {
//    $(window).scroll(function() {
//    if ( ($(window).scrollTop() >= $(document).height() - $(window).height() - 3000)
//         && ($('#container').attr("data-infinite-scroll-status") == 'ready') ) {
//	load_log_lines();
//    }
//  })
//});


jQuery(function($) {
    $(window).bind('DOMMouseScroll mousewheel', function(e){
	if (e.originalEvent.wheelDelta > 0 || e.originalEvent.detail < 0) {
	    if ( ( ($(window).scrollTop() < 3000) || ($(document).height() <= $(window).height()) ) 
		 && ($('#container').attr("data-infinite-scroll-earlier-status") == 'ready') ) {
		load_log_lines(false);
	    }
	}
	else {
	    // scrolling down
	    if ( ( ($(window).scrollTop() >= $(document).height() - $(window).height() - 3000)
		   || ($(document).height() <= $(window).height()))
		 && ($('#container').attr("data-infinite-scroll-status") == 'ready') ) {
		load_log_lines(true);
	    }
	}
  });
});
