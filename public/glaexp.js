jQuery(document).ready(function($){
  // put h1 in a form
  var h1 = $('h1');
  h1.after('<form><h1>'+h1.html()+'</h1></form>');
  h1.remove();

  // turn amount into an input
  var amount = $('.titular_amount');
  amount.after('<input type="text" name="q">');
  $('form h1 input[type="text"]').val(amount.html());
  amount.remove();

  // turn ? into a submit
  var ques = $('.titular_ques');
  ques.after('<input type="submit">');
  $('form h1 input[type="submit"]').val(ques.html());
  ques.remove();
});
