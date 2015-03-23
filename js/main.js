// This thing checks for the status
var updateStatus = function() {
  $.getJSON('/status', {}, function(data, textStatus, xhr) {
    $("#status").html("<b>" + data.in_sync + "</b> / " + data.files + " sketch files in sync");
    if (data.in_sync != data.files) {
      window.setTimeout(updateStatus, 2000);
    }
  });
}

var search = function(query) {
  $(window).scrollTop(0);
  if (query.length == 0) {
    $("#no-results").show();
    $("#results").html('');
    return;
  }
  $.post('/search', {
    query: query
  }, function(data, status, xhr) {
    $("#no-results").hide();
    $("#results").html('');

    var slicesShown = 0;

    for (var i in data.results) {
      var result = data.results[i];
      result.basename = result.file.split('/').pop();
      $("#results").append(
        "<div class='result-file row'>" +
          "<div class='result-filename-container'>" +
            "<h2 class='result-filename'><i class='fa fa-file-image-o'></i> " + result.basename + "</h2>" +
            "<span><i class='fa fa-clock-o'></i> " + new Date(result.last_modified).toRelativeTime() + "</span> &middot; " +
            "<span><a target='_new' href='/download/" + result.file_id + "'>Download from Dropbox</a></span>" +
          "</div>" + result.slices.map(function(slice) {
        var thumb_url = slice.path.replace('.png', '.thumb.jpg'),
            image_attr = (slicesShown < 6) ? "src='" + thumb_url + "'" : "data-original='" + thumb_url + "'";
        slicesShown += 1;

        return "<div class='result-slice col-xs-4'><a href='" + slice.path + "' target='_new'><h3 class='result-slice-layer-title'>" + slice.layer + "</h3><img " + image_attr + " /></a></div>";
      }).join(' ') + "</div>");
    }
    resetScrollListeners();
  });
};

// this is necessary to prevent the page from coming to a scrolling crawl:
var resetScrollListeners = function() {
  $(window).off('scroll');
  $("#results img").lazyload();
  $(window).on('scroll', handleScroll);

}

var handleScroll = function(e) {
  var $container = $("#search-container");

  if (window.scrollY < 60 && $container.hasClass('search-mode')) {
    return;
  }

  var invisibleLine = window.scrollY + 60;
  // find the last .result-file above the invisible line
  var lastAboveLine;
  $('.result-file').each(function(i) {
    if ($(this).offset().top < invisibleLine) {
      lastAboveLine = $(this);
    }
  });

  if (lastAboveLine) {
    $container.removeClass('search-mode');
    $container.addClass('filename-mode');
    $container.find('.search-icon').removeClass('fa-search').addClass('fa-chevron-left');
    $container.find('.search-or-filename #search').hide();
    $container.find('.search-or-filename #filename').html(
      lastAboveLine.find('.result-filename').html()
    );
    $container.find('.search-or-filename #filename').show();
  } else {
    $container.removeClass('filename-mode');
    $container.addClass('search-mode');
    $container.find('.search-icon').removeClass('fa-chevron-left').addClass('fa-search');
    $container.find('.search-or-filename #search').show();
    $container.find('.search-or-filename #filename').hide();
  }
};

$(function() {
  updateStatus();

  // It's all about search of course!
  $("#search-container").on('click', function(e) {
    if ($('#search-container').hasClass('search-mode')) {
      $("#search").focus(); // fake it till you make it!
    } else {
      $(window).scrollTop(0);
      setTimeout(function() {
        $("#search").focus(); // fake it till you make it!
      }, 100);
    }
  });
  $("#search").focus();

  if ($("#search").val().length > 0) {
    search($("#search").val());
  }
  $('#search').on('keyup', function(e) {
    search(e.target.value);
  });
});
