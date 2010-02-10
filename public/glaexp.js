jQuery(document).ready(function($){
  // put h1 in a form
  var h1 = $('h1');
  h1.after('<form><h1>'+h1.html()+'</h1></form>');
  h1.remove();

  // turn amount into an input
  var amount = $('.titular_amount');
  amount.after('<input type="text" name="q" class="text">');
  var amount_input = $('form h1 input[type="text"]');
  amount_input.val(amount.html());
  $('form h1 input[type="text"]').val(amount.html());
  amount.remove();

  amount_input.focus(function(){
    if ($('form h1 input[type="submit"]').length == 0) {
      // turn ? into a submit
      var ques = $('.titular_ques');
      ques.after('<input type="submit" class="submit">');
      $('form h1 input[type="submit"]').val(ques.html());
      ques.remove();
    }

    // Select-all
    $(this).select();
  });

  amount_input.mouseup(function(){
    return false;
  });

});
