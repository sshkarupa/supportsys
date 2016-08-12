var main = function() {
  $('#datetimepicker').datetimepicker({
    locale: 'ru'
  });

  $("#id_cash").mask("999 999 999 999");
};

$(document).ready(main);


