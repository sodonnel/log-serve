// Goto Date form
jQuery(function($) {
    $("#gotoDate").submit(function( event ) {
	var filekey  = $('#container').attr("data-filekey")
	$.post("/file/"+filekey+"/date", $("#gotoDate").serialize(), function(response) {
	    eval(response);
	}).fail(function() {
	    alert( "Failed to goto the date - server error" );
	});
	return false;
    });
});


jQuery(function($) {
    $("#startButton,#endButton,#downButton,#upButton").click(function( event ) {
	var filekey = $('#container').attr("data-filekey");
	var button = event.target.id;
	var new_position = null;

	if (button == 'startButton') {
	    new_position = 0;
	} else if (button == 'endButton') {
	    new_position = 'end';
	} else {
	    var visible = first_visible_logline();
	    if (button == 'downButton') {
		new_position = Number($(visible).attr('sp')) + 524288; // half a meg
	    } else {
		new_position = Number($(visible).attr('sp')) - 524288; // half a meg
	    }
	}
	$.get("/file/"+filekey+"/position/"+new_position, function(response) {
	    eval(response);
	}).fail(function() {
	    alert( "Failed to goto the end of the file - server error" );
	});
	return false;
    });
});

function first_visible_logline() {
    var visible = null;
    $('#code tr').each( function(l) {
	if ($(this).position().top >= $(window).scrollTop() + 50) {
	    visible = this
	    return false;
	}
    });
    return visible;
}

function scroll_to_position(pos, highlight) {
    var scrollSet = false
    $('#code tr').each( function(l) {
	if (Number($(this).attr('sp')) >= pos) {
	    scrollSet = true;
	    $(this).get(0).scrollIntoView()
	    // we actually need to shift by an extra 50px due to the
	    // menu at the top of the page
	    $('html, body').scrollTop($('html, body').scrollTop() - 65);
	    if (highlight == true) {
		$(this).css('background-color', 'yellow')
	    }
	    return false;
	}
    });
    if (scrollSet == false) {
	window.scrollTo(0,document.body.scrollHeight);
    }
}

function earliest_position_in_viewer() {
    if ($('#code tr').length == 0) {
	return 0;
    } else {
	return Number($($('#code tr').first()).attr('sp'));
    }
}

function latest_position_in_viewer() {
    if ($('#code tr').length == 0) {
	return 0;
    } else {
	return Number($($('#code tr').last()).attr('ep'));
    }
}

function load_log_lines(forwards) {
    var statusAttr = forwards ? "data-infinite-scroll-status" : "data-infinite-scroll-earlier-status"
    if ($('#container').attr(statusAttr)  != 'ready' ) {
	return;
    }

    $('#container').attr(statusAttr, "loading");
    var filekey  = $('#container').attr("data-filekey")
    var position = forwards ? latest_position_in_viewer() : earliest_position_in_viewer()
    
    var url = forwards ? "more" : "less"
    $.get("/file/"+filekey+"/"+url+"/"+position, function(response) {
	eval(response)
    }).fail(function() {
	alert( "Failed to retrieve logs - server error" );
	$('#container').attr(statusAttr, 'ready');
    });
}


function reset() {
    $('#container').attr('data-infinite-scroll-status', 'ready');
    $('#container').attr('data-infinite-scroll-earlier-status', 'ready');
    $('#code').empty();
}

function reset_position(new_position) {
    // This method will set the data-infinite-scroll-position, clear the loglines
    // and then call load_log_lines to load new logs
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
