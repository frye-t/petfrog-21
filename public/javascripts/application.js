$(function() {
  const mv_amt = 34;
  const arr = ['dealer', 'player']
  for (const name of arr) {
    console.log(name);
    num_cards = document.querySelectorAll('.' + name + '-card').length;

    // Shift each card individually the proper amount
    for (let i = 0; i < num_cards; i++) {
      mv_x_card = i * mv_amt;

      $('img[id=' + name + '-card-' + i + ']').css({
        transform:'translateX(-' + mv_x_card + 'px)'
      });
    };
    
    // Shift the entire list back to the right to re-center
    mv_x_list = (num_cards - 1) * (mv_amt / 2)
    $('ul[id=' + name + '-hand]').css({
      transform:'translateX(' + mv_x_list + 'px)'
    });

    // Shift score box same amount as last card moved to re-position
    mv_x_score = (num_cards - 1) * mv_amt;
    $('div[id=' + name + '-score]').css({
      transform:'translateX(-' + mv_x_score + 'px)'
    });
  }

  $("form#quit").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This will reset your balance!");
    if (ok) {
      this.submit();
    }
  });
}); 
