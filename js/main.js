// This thing checks for the status
var updateStatus = function() {
  $.getJSON('/status', {}, function(data, textStatus, xhr) {
    $("#status").html("<b>" + data.in_sync + "</b> / " + data.files + " files in sync");
    if (data.in_sync != data.files) {
      window.setTimeout(updateStatus, 2000);
    }
  });
}

var search = function(query) {
  $.post('/search', {
    query: query
  }, function(data, status, xhr) {
    $('#query').html('<h2>results for ' + data.search.join(' ') + '</h2>');
    $("#results").html('');

    for (i in data.results) {
      var result = data.results[i];
      result.basename = result.dropbox_url.split('/').pop();
      $("#results").append("<div class='result' style='background-image:url(" + result.image_url.replace('.png', '.thumb.jpg') + ");'><p class='result-filename'>" +
                           result.basename + "</p><p class='result-slice'>" +
                           result.layer + "</p></div>");
    }
    console.log(data);
    $('#results').append(data.results);
  });
}

$(function() {
  updateStatus();

  // It's all about search of course!
  $("#search-container").on('click', function(e) {
    $("#search").focus(); // fake it till you make it!
  });
  $("#search").focus();

  $('#search').on('keyup', function(e) {
    search(e.target.value);
  });
});
