async function generateClubSquad(){

if(Storage.exists("signed_players_by_club"))
return;

...

Storage.save("signed_players_by_club",players);

}