function calculateMarketValue(){

const clubs=Storage.load("signed_players_by_club",{});

...

Storage.save("club_market_values",values);

}