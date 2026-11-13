import 'dart:math';

/// أسماء لاعبين مولَّدين منطقية حسب الجنسية (بالحروف اللاتينية كاللاعبين الحقيقيين)
/// المفتاح: اسم الجنسية بالعربية كما في Player.nat
const Map<String, (List<String>, List<String>)> kNames = {
  'المغرب': (['Youssef', 'Amine', 'Hamza', 'Ayoub', 'Yassine', 'Karim', 'Mehdi', 'Reda', 'Bilal', 'Ilyas', 'Anas', 'Zakaria', 'Soufiane', 'Oussama', 'Achraf', 'Hakim', 'Nabil', 'Walid', 'Othmane', 'Badr'],
      ['El Amrani', 'Benali', 'El Idrissi', 'Alaoui', 'Tazi', 'Bennani', 'El Fassi', 'Chraibi', 'Ouazzani', 'Berrada', 'Lahlou', 'Mansouri', 'Ziani', 'Saidi', 'El Khatib', 'Haddad', 'Amrabat', 'Bouzid', 'Rahmouni', 'El Moutawakil']),
  'الجزائر': (['Riyad', 'Islam', 'Yacine', 'Sofiane', 'Aymen', 'Mohamed', 'Ramy', 'Nabil', 'Said', 'Djamel', 'Adem', 'Houssem', 'Hichem', 'Amir', 'Farid', 'Rafik', 'Ilyes', 'Abdelkader', 'Walid', 'Zinedine'],
      ['Bensebaini', 'Belaili', 'Slimani', 'Boudaoui', 'Mandi', 'Bennacer', 'Atal', 'Brahimi', 'Ounas', 'Feghouli', 'Bounedjah', 'Zerrouki', 'Benrahma', 'Aouar', 'Hadjam', 'Chaibi', 'Khelifi', 'Mahrez', 'Belkacem', 'Meziane']),
  'تونس': (['Wahbi', 'Youssef', 'Ellyes', 'Hamza', 'Aymen', 'Ali', 'Anis', 'Mohamed', 'Seifeddine', 'Naim', 'Bilel', 'Firas', 'Montassar', 'Ghailene', 'Hannibal', 'Oussama', 'Rami', 'Skander', 'Issam', 'Taha'],
      ['Khazri', 'Msakni', 'Skhiri', 'Talbi', 'Laidouni', 'Sliti', 'Abdi', 'Ben Romdhane', 'Jebali', 'Mejbri', 'Chaalali', 'Drager', 'Ben Slimane', 'Haddadi', 'Trabelsi', 'Bouguerra', 'Ayari', 'Gharbi', 'Maaloul', 'Chikhaoui']),
  'مصر': (['Mohamed', 'Ahmed', 'Mahmoud', 'Omar', 'Karim', 'Mostafa', 'Ali', 'Hossam', 'Tarek', 'Amr', 'Ibrahim', 'Marwan', 'Yasser', 'Ramadan', 'Ziad', 'Hany', 'Abdallah', 'Islam', 'Khaled', 'Walid'],
      ['Hassan', 'Abdelhamid', 'El Shenawy', 'Fathy', 'Zizo', 'Sobhy', 'Ashour', 'Hegazi', 'Ibrahim', 'Gaber', 'Salah', 'Elneny', 'Trezeguet', 'Kouka', 'Abdelmonem', 'Mohsen', 'Mostafa', 'Kamal', 'Fawzy', 'El Sayed']),
  'السعودية': (['Salem', 'Abdullah', 'Mohammed', 'Fahad', 'Faisal', 'Saud', 'Nasser', 'Turki', 'Khalid', 'Yasser', 'Ali', 'Hassan', 'Sultan', 'Abdulrahman', 'Ayman', 'Mukhtar', 'Saleh', 'Hamad', 'Nawaf', 'Riyadh'],
      ['Al-Dawsari', 'Al-Shehri', 'Al-Faraj', 'Al-Ghannam', 'Al-Amri', 'Al-Hamdan', 'Al-Harbi', 'Al-Owais', 'Al-Buraikan', 'Al-Malki', 'Al-Abed', 'Al-Qahtani', 'Al-Najei', 'Kanno', 'Al-Bulayhi', 'Al-Tambakti', 'Al-Shahrani', 'Al-Zubaidi', 'Al-Mutairi', 'Al-Otaibi']),
  'السنغال': (['Sadio', 'Idrissa', 'Cheikhou', 'Ismaila', 'Pape', 'Boulaye', 'Abdou', 'Moussa', 'Krepin', 'Famara', 'Nampalys', 'Bamba', 'Lamine', 'Habib', 'Mamadou', 'Ousmane', 'Youssouf', 'Formose', 'Saliou', 'Papa'],
      ['Mane', 'Gueye', 'Kouyate', 'Sarr', 'Diop', 'Dia', 'Diallo', 'Diatta', 'Ndiaye', 'Mendy', 'Fall', 'Niang', 'Sabaly', 'Gomis', 'Camara', 'Seck', 'Sow', 'Cisse', 'Ba', 'Thiam']),
  'نيجيريا': (['Victor', 'Samuel', 'Kelechi', 'Ademola', 'Wilfred', 'Moses', 'Alex', 'Chidozie', 'Taiwo', 'Ola', 'Emmanuel', 'Calvin', 'Terem', 'Frank', 'Joe', 'Paul', 'Tyronne', 'Kenneth', 'Chukwueze', 'Bright'],
      ['Osimhen', 'Chukwueze', 'Iheanacho', 'Lookman', 'Ndidi', 'Simon', 'Iwobi', 'Awaziem', 'Awoniyi', 'Aribo', 'Onuachu', 'Ajayi', 'Bassey', 'Aina', 'Omeruo', 'Dessers', 'Sanusi', 'Osayi-Samuel', 'Okoye', 'Adeyemi']),
  'غانا': (['Thomas', 'Mohammed', 'Jordan', 'Inaki', 'Antoine', 'Kamaldeen', 'Daniel', 'Tariq', 'Abdul', 'Baba', 'Gideon', 'Joseph', 'Salis', 'Alexander', 'Richmond', 'Ernest', 'Kudus', 'Elisha', 'Fatawu', 'Osman'],
      ['Partey', 'Kudus', 'Ayew', 'Williams', 'Semenyo', 'Sulemana', 'Amartey', 'Lamptey', 'Issahaku', 'Mensah', 'Djiku', 'Salisu', 'Baba', 'Owusu', 'Boateng', 'Asante', 'Opoku', 'Bukari', 'Fuseini', 'Adjei']),
  'ساحل العاج': (['Franck', 'Sebastien', 'Wilfried', 'Nicolas', 'Simon', 'Seko', 'Evan', 'Odilon', 'Ibrahim', 'Willy', 'Serge', 'Max', 'Jean', 'Oumar', 'Christian', 'Amad', 'Maxwel', 'Eric', 'Gervinho', 'Yaya'],
      ['Kessie', 'Haller', 'Zaha', 'Pepe', 'Fofana', 'Sangare', 'Ndicka', 'Kossounou', 'Boly', 'Gradel', 'Diallo', 'Gbamin', 'Traore', 'Aurier', 'Bailly', 'Cornet', 'Kone', 'Seri', 'Bamba', 'Doumbia']),
  'الكاميرون': (['Andre', 'Vincent', 'Karl', 'Eric', 'Bryan', 'Collins', 'Martin', 'Christopher', 'Olivier', 'Nicolas', 'Jean', 'Samuel', 'Pierre', 'Georges', 'Harold', 'Moumi', 'Frank', 'Jerome', 'Yvan', 'Gael'],
      ['Onana', 'Aboubakar', 'Toko Ekambi', 'Mbeumo', 'Anguissa', 'Zambo', 'Choupo-Moting', 'Bassogog', 'Hongla', 'Fai', 'Ngadeu', 'Neyou', 'Etta Eyong', 'Wooh', 'Ntcham', 'Tchamba', 'Oyongo', 'Ebosse', 'Kunde', 'Nkoulou']),
  'مالي': (['Moussa', 'Yves', 'Amadou', 'Cheick', 'Adama', 'Ibrahima', 'Kalifa', 'Hamari', 'Mamadou', 'Lassana', 'Souleymane', 'Boubacar', 'Falaye', 'Diadie', 'El Bilal', 'Massadio', 'Salif', 'Mohamed', 'Nene', 'Sekou'],
      ['Bissouma', 'Doumbia', 'Traore', 'Haidara', 'Sissoko', 'Kouyate', 'Coulibaly', 'Samassekou', 'Diaby', 'Sacko', 'Toure', 'Kone', 'Diarra', 'Dembele', 'Camara', 'Diakite', 'Keita', 'Maiga', 'Sidibe', 'Konate']),
  'إنجلترا': (['Harry', 'Jack', 'Jude', 'Bukayo', 'Phil', 'Declan', 'Marcus', 'Kyle', 'Reece', 'Luke', 'Ollie', 'Conor', 'Callum', 'Mason', 'Ben', 'Tom', 'James', 'Cole', 'Morgan', 'Adam'],
      ['Walker', 'Stones', 'Rice', 'Foden', 'Palmer', 'Gallagher', 'Mount', 'Grealish', 'Maguire', 'Shaw', 'Trippier', 'Henderson', 'Pickford', 'Watkins', 'Gordon', 'White', 'Mainoo', 'Konsa', 'Wharton', 'Eze']),
  'فرنسا': (['Antoine', 'Theo', 'Kylian', 'Ousmane', 'Aurelien', 'Eduardo', 'Adrien', 'Lucas', 'Jules', 'Dayot', 'Randal', 'Warren', 'Benjamin', 'Olivier', 'Raphael', 'Mathys', 'Clement', 'Florian', 'Maxence', 'Rayan'],
      ['Dubois', 'Martin', 'Bernard', 'Moreau', 'Laurent', 'Lefebvre', 'Fontaine', 'Rousseau', 'Mercier', 'Girard', 'Lambert', 'Perrin', 'Chevalier', 'Blanc', 'Garnier', 'Faure', 'Marchand', 'Barbier', 'Colin', 'Renard']),
  'إسبانيا': (['Alvaro', 'Pablo', 'Marc', 'Dani', 'Mikel', 'Sergio', 'Jorge', 'Ferran', 'Fabian', 'Alejandro', 'Unai', 'Iker', 'Carlos', 'Javier', 'Raul', 'Adrian', 'Ruben', 'David', 'Rodrigo', 'Gerard'],
      ['Garcia', 'Fernandez', 'Lopez', 'Martinez', 'Sanchez', 'Perez', 'Gomez', 'Ruiz', 'Hernandez', 'Jimenez', 'Moreno', 'Navarro', 'Torres', 'Dominguez', 'Vazquez', 'Ramos', 'Gil', 'Serrano', 'Molina', 'Castro']),
  'ألمانيا': (['Leon', 'Jonas', 'Felix', 'Lukas', 'Niklas', 'Florian', 'Maximilian', 'Tim', 'Jan', 'Kai', 'Julian', 'Moritz', 'Marcel', 'Robin', 'Fabian', 'Philipp', 'Lars', 'Patrick', 'Sebastian', 'Nico'],
      ['Muller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker', 'Hoffmann', 'Schafer', 'Koch', 'Richter', 'Klein', 'Wolf', 'Neumann', 'Schwarz', 'Zimmermann', 'Braun', 'Kruger', 'Hartmann']),
  'إيطاليا': (['Lorenzo', 'Federico', 'Nicolo', 'Matteo', 'Gianluca', 'Alessandro', 'Davide', 'Andrea', 'Marco', 'Giovanni', 'Riccardo', 'Simone', 'Luca', 'Domenico', 'Manuel', 'Sandro', 'Giacomo', 'Mattia', 'Francesco', 'Samuele'],
      ['Rossi', 'Russo', 'Ferrari', 'Esposito', 'Bianchi', 'Romano', 'Colombo', 'Ricci', 'Marino', 'Greco', 'Bruno', 'Gallo', 'Conti', 'De Luca', 'Mancini', 'Costa', 'Giordano', 'Rizzo', 'Lombardi', 'Moretti']),
  'البرتغال': (['Joao', 'Diogo', 'Ruben', 'Bernardo', 'Goncalo', 'Pedro', 'Nuno', 'Rafael', 'Tiago', 'Andre', 'Miguel', 'Francisco', 'Vitinha', 'Renato', 'Rui', 'Daniel', 'Tomas', 'Gil', 'Fabio', 'Afonso'],
      ['Silva', 'Santos', 'Ferreira', 'Pereira', 'Oliveira', 'Costa', 'Rodrigues', 'Martins', 'Sousa', 'Fernandes', 'Goncalves', 'Gomes', 'Lopes', 'Marques', 'Alves', 'Almeida', 'Ribeiro', 'Pinto', 'Carvalho', 'Teixeira']),
  'هولندا': (['Daan', 'Sem', 'Lars', 'Jesse', 'Teun', 'Joey', 'Wout', 'Stefan', 'Matthijs', 'Cody', 'Micky', 'Xavi', 'Jurrien', 'Memphis', 'Denzel', 'Tijjani', 'Brian', 'Bart', 'Ryan', 'Noa'],
      ['De Jong', 'Van Dijk', 'Bakker', 'Visser', 'Smit', 'Meijer', 'De Boer', 'Mulder', 'De Groot', 'Bos', 'Vos', 'Peters', 'Hendriks', 'Van Leeuwen', 'Dekker', 'Brouwer', 'De Wit', 'Dijkstra', 'Smits', 'De Graaf']),
  'بلجيكا': (['Kevin', 'Romelu', 'Youri', 'Jeremy', 'Leandro', 'Charles', 'Amadou', 'Thomas', 'Yannick', 'Dries', 'Hans', 'Timothy', 'Arthur', 'Koni', 'Zeno', 'Lois', 'Wout', 'Thorgan', 'Orel', 'Jan'],
      ['De Bruyne', 'Lukaku', 'Tielemans', 'Doku', 'Trossard', 'De Ketelaere', 'Onana', 'Meunier', 'Carrasco', 'Mertens', 'Vanaken', 'Castagne', 'Theate', 'Debast', 'Openda', 'Vermeeren', 'Faes', 'Mangala', 'Witsel', 'Verbruggen']),
  'البرازيل': (['Gabriel', 'Matheus', 'Lucas', 'Vinicius', 'Rodrygo', 'Bruno', 'Joao', 'Pedro', 'Raphinha', 'Endrick', 'Casemiro', 'Danilo', 'Eder', 'Fabinho', 'Gustavo', 'Igor', 'Leandro', 'Murilo', 'Savio', 'Wesley'],
      ['Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Alves', 'Pereira', 'Lima', 'Gomes', 'Costa', 'Ribeiro', 'Martins', 'Carvalho', 'Almeida', 'Barbosa', 'Araujo', 'Cardoso', 'Nascimento', 'Moreira']),
  'الأرجنتين': (['Lionel', 'Julian', 'Lautaro', 'Enzo', 'Alexis', 'Nicolas', 'Rodrigo', 'Cristian', 'Emiliano', 'Giovani', 'Leandro', 'Facundo', 'Matias', 'Franco', 'Thiago', 'Exequiel', 'Valentin', 'Nahuel', 'Gonzalo', 'Santiago'],
      ['Fernandez', 'Alvarez', 'Martinez', 'Gonzalez', 'Rodriguez', 'Lopez', 'Gomez', 'Diaz', 'Romero', 'Acuna', 'Molina', 'Paredes', 'Otamendi', 'Montiel', 'Palacios', 'Barco', 'Garnacho', 'Mastantuono', 'Medina', 'Soule']),
  'أوروغواي': (['Federico', 'Darwin', 'Ronald', 'Luis', 'Manuel', 'Nicolas', 'Rodrigo', 'Jose', 'Mathias', 'Facundo', 'Agustin', 'Maxi', 'Sebastian', 'Brian', 'Santiago', 'Matias', 'Lucas', 'Emiliano', 'Giorgian', 'Cristian'],
      ['Valverde', 'Nunez', 'Araujo', 'Ugarte', 'Bentancur', 'De la Cruz', 'Gimenez', 'Olivera', 'Vina', 'Pellistri', 'Canobbio', 'Rochet', 'Cabral', 'Rodriguez', 'Torres', 'Viera', 'Bueno', 'Coates', 'Cardozo', 'Sosa']),
  'كولومبيا': (['James', 'Luis', 'Juan', 'Jhon', 'Rafael', 'Richard', 'Davinson', 'Jefferson', 'Yerry', 'Daniel', 'Miguel', 'Kevin', 'Santiago', 'Mateus', 'Jorge', 'Andres', 'Carlos', 'Radamel', 'Johan', 'Jaminton'],
      ['Rodriguez', 'Diaz', 'Cuadrado', 'Arias', 'Lerma', 'Mina', 'Sanchez', 'Munoz', 'Cordoba', 'Borre', 'Uribe', 'Campaz', 'Lucumi', 'Castano', 'Falcao', 'Zapata', 'Quintero', 'Ospina', 'Mojica', 'Barrios']),
  'المكسيك': (['Hirving', 'Raul', 'Edson', 'Jesus', 'Cesar', 'Luis', 'Carlos', 'Orbelin', 'Johan', 'Santiago', 'Roberto', 'Erick', 'Henry', 'Alexis', 'Diego', 'Uriel', 'Jorge', 'Guillermo', 'Rodolfo', 'Kevin'],
      ['Lozano', 'Jimenez', 'Alvarez', 'Gallardo', 'Montes', 'Chavez', 'Romo', 'Pineda', 'Vasquez', 'Gimenez', 'Alvarado', 'Sanchez', 'Martin', 'Vega', 'Lainez', 'Araujo', 'Antuna', 'Rodriguez', 'Pizarro', 'Corona']),
  'أمريكا': (['Christian', 'Weston', 'Tyler', 'Giovanni', 'Timothy', 'Sergino', 'Ricardo', 'Brenden', 'Josh', 'Matt', 'Yunus', 'Folarin', 'Haji', 'Malik', 'Jordan', 'Cameron', 'Tanner', 'Antonee', 'Joe', 'Cole'],
      ['Pulisic', 'McKennie', 'Adams', 'Reyna', 'Weah', 'Dest', 'Pepi', 'Aaronson', 'Sargent', 'Turner', 'Musah', 'Balogun', 'Wright', 'Tillman', 'Morris', 'Carter-Vickers', 'Zimmerman', 'Robinson', 'Scally', 'Richards']),
  'اليابان': (['Takefusa', 'Kaoru', 'Daichi', 'Ritsu', 'Wataru', 'Takumi', 'Hiroki', 'Junya', 'Yuki', 'Ao', 'Kyogo', 'Reo', 'Shogo', 'Koki', 'Keito', 'Yukinari', 'Takehiro', 'Ayase', 'Hayato', 'Sota'],
      ['Kubo', 'Mitoma', 'Kamada', 'Doan', 'Endo', 'Minamino', 'Itakura', 'Ito', 'Soma', 'Tanaka', 'Furuhashi', 'Hatate', 'Taniguchi', 'Ito', 'Nakamura', 'Sugawara', 'Tomiyasu', 'Ueda', 'Kawamura', 'Maeda']),
  'كوريا الجنوبية': (['Heung-min', 'Min-jae', 'Kang-in', 'Hee-chan', 'Jae-sung', 'Woo-yeong', 'Gue-sung', 'Seung-ho', 'In-beom', 'Young-woo', 'Hyeon-gyu', 'Jin-su', 'Myung-jae', 'Tae-hwan', 'Ji-sung', 'Sung-yueng', 'Dong-jun', 'Ho-yeon', 'Jun-ho', 'Han-beom'],
      ['Son', 'Kim', 'Lee', 'Hwang', 'Jeong', 'Cho', 'Park', 'Seol', 'Kwon', 'Hong', 'Oh', 'Yang', 'Bae', 'Yoon', 'Song', 'Lim', 'Ahn', 'Choi', 'Jung', 'Han']),
  'تركيا': (['Hakan', 'Arda', 'Kenan', 'Ferdi', 'Cenk', 'Orkun', 'Zeki', 'Mert', 'Caglar', 'Ismail', 'Emre', 'Burak', 'Baris', 'Yusuf', 'Salih', 'Abdulkerim', 'Kerem', 'Irfan', 'Can', 'Ozan'],
      ['Calhanoglu', 'Guler', 'Yildiz', 'Kadioglu', 'Tosun', 'Kokcu', 'Celik', 'Muldur', 'Soyuncu', 'Yuksek', 'Demiral', 'Yilmaz', 'Ozcan', 'Aktürkoglu', 'Akgun', 'Bardakci', 'Kahveci', 'Kabak', 'Tekdemir', 'Cakir']),
  'كرواتيا': (['Luka', 'Ivan', 'Mateo', 'Marcelo', 'Josko', 'Mario', 'Andrej', 'Nikola', 'Lovro', 'Josip', 'Borna', 'Dominik', 'Ante', 'Martin', 'Domagoj', 'Petar', 'Bruno', 'Duje', 'Luka', 'Marko'],
      ['Modric', 'Perisic', 'Kovacic', 'Brozovic', 'Gvardiol', 'Pasalic', 'Kramaric', 'Vlasic', 'Majer', 'Stanisic', 'Sosa', 'Livakovic', 'Budimir', 'Juranovic', 'Pongracic', 'Sucic', 'Erlic', 'Petkovic', 'Ivanusec', 'Bradaric']),
  'صربيا': (['Dusan', 'Aleksandar', 'Sergej', 'Filip', 'Nemanja', 'Luka', 'Strahinja', 'Andrija', 'Milos', 'Nikola', 'Lazar', 'Darko', 'Marko', 'Stefan', 'Vanja', 'Uros', 'Veljko', 'Ivan', 'Predrag', 'Petar'],
      ['Vlahovic', 'Mitrovic', 'Milinkovic-Savic', 'Kostic', 'Tadic', 'Jovic', 'Pavlovic', 'Zivkovic', 'Maksimovic', 'Ilic', 'Radonjic', 'Lukic', 'Gudelj', 'Veljkovic', 'Birmancevic', 'Milenkovic', 'Rajkovic', 'Samardzic', 'Grujic', 'Stojkovic']),
  'بولندا': (['Robert', 'Piotr', 'Wojciech', 'Jakub', 'Krzysztof', 'Arkadiusz', 'Sebastian', 'Matty', 'Nicola', 'Karol', 'Przemyslaw', 'Kamil', 'Bartosz', 'Jan', 'Michal', 'Tomasz', 'Mateusz', 'Pawel', 'Adam', 'Dawid'],
      ['Lewandowski', 'Zielinski', 'Szczesny', 'Kiwior', 'Bednarek', 'Milik', 'Szymanski', 'Cash', 'Zalewski', 'Swiderski', 'Frankowski', 'Glik', 'Piatek', 'Wieteska', 'Buksa', 'Kaminski', 'Nowak', 'Kowalski', 'Wisniewski', 'Wojcik']),
  'الدنمارك': (['Christian', 'Pierre-Emile', 'Rasmus', 'Mikkel', 'Andreas', 'Joachim', 'Kasper', 'Simon', 'Jonas', 'Yussuf', 'Thomas', 'Martin', 'Victor', 'Mathias', 'Jens', 'Morten', 'Joakim', 'Alexander', 'Anders', 'Oliver'],
      ['Eriksen', 'Hojbjerg', 'Hojlund', 'Damsgaard', 'Christensen', 'Andersen', 'Schmeichel', 'Kjaer', 'Skov Olsen', 'Poulsen', 'Delaney', 'Maehle', 'Wind', 'Dolberg', 'Larsen', 'Hansen', 'Pedersen', 'Nielsen', 'Jensen', 'Kristensen']),
  'السويد': (['Alexander', 'Dejan', 'Viktor', 'Emil', 'Victor', 'Jesper', 'Ken', 'Robin', 'Mattias', 'Gustav', 'Anthony', 'Hugo', 'Isak', 'Filip', 'Jens', 'Sebastian', 'Marcus', 'Joel', 'Oscar', 'Erik'],
      ['Isak', 'Kulusevski', 'Gyokeres', 'Forsberg', 'Lindelof', 'Olsen', 'Claesson', 'Svanberg', 'Augustinsson', 'Elanga', 'Johansson', 'Karlsson', 'Andersson', 'Eriksson', 'Larsson', 'Nilsson', 'Svensson', 'Lindgren', 'Berg', 'Holm']),
  'النرويج': (['Erling', 'Martin', 'Alexander', 'Sander', 'Oscar', 'Kristian', 'Mohamed', 'Julian', 'Leo', 'Andreas', 'Fredrik', 'Joshua', 'Marcus', 'Stefan', 'Morten', 'Ola', 'Jorgen', 'Patrick', 'David', 'Antonio'],
      ['Haaland', 'Odegaard', 'Sorloth', 'Berge', 'Bobb', 'Thorstvedt', 'Elyounoussi', 'Ryerson', 'Ostigard', 'Nusa', 'Strand Larsen', 'Aursnes', 'Ajer', 'Hauge', 'Johansen', 'Hansen', 'Larsen', 'Olsen', 'Berg', 'Dahl']),
  'سويسرا': (['Granit', 'Manuel', 'Breel', 'Yann', 'Xherdan', 'Ricardo', 'Fabian', 'Denis', 'Noah', 'Michel', 'Remo', 'Dan', 'Silvan', 'Ruben', 'Cedric', 'Nico', 'Zeki', 'Kwadwo', 'Djibril', 'Steven'],
      ['Xhaka', 'Akanji', 'Embolo', 'Sommer', 'Shaqiri', 'Rodriguez', 'Schar', 'Zakaria', 'Okafor', 'Aebischer', 'Freuler', 'Ndoye', 'Widmer', 'Vargas', 'Zuber', 'Elvedi', 'Amdouni', 'Duah', 'Sow', 'Zeqiri']),
  'النمسا': (['David', 'Marcel', 'Marko', 'Konrad', 'Christoph', 'Xaver', 'Nicolas', 'Florian', 'Stefan', 'Patrick', 'Philipp', 'Kevin', 'Maximilian', 'Michael', 'Romano', 'Alexander', 'Gernot', 'Andreas', 'Mathias', 'Leopold'],
      ['Alaba', 'Sabitzer', 'Arnautovic', 'Laimer', 'Baumgartner', 'Schlager', 'Seiwald', 'Grillitsch', 'Posch', 'Danso', 'Trauner', 'Lienhart', 'Gregoritsch', 'Wimmer', 'Schmid', 'Weimann', 'Wober', 'Prass', 'Bernardo', 'Schopf']),
  'إسكتلندا': (['Andrew', 'Scott', 'John', 'Billy', 'Kieran', 'Callum', 'Che', 'Ryan', 'Stuart', 'Lewis', 'Ben', 'Lyndon', 'Jack', 'Ross', 'Kenny', 'Liam', 'Nathan', 'Lawrence', 'Angus', 'Craig'],
      ['Robertson', 'McTominay', 'McGinn', 'Gilmour', 'Tierney', 'McGregor', 'Adams', 'Christie', 'Armstrong', 'Hendry', 'Hickey', 'Dykes', 'Shankland', 'Gunn', 'Patterson', 'Cooper', 'Ferguson', 'Campbell', 'Murray', 'Stewart']),
  'أيرلندا': (['Evan', 'Nathan', 'Caoimhin', 'Matt', 'Seamus', 'Chiedozie', 'Jason', 'Josh', 'Troy', 'Adam', 'Dara', 'Gavin', 'Will', 'Michael', 'Callum', 'Liam', 'Sean', 'Conor', 'Ryan', 'John'],
      ['Ferguson', 'Collins', 'Kelleher', 'Doherty', 'Coleman', 'Ogbene', 'Knight', 'Cullen', 'Parrott', 'Idah', "O'Shea", 'Bazunu', 'Smallbone', 'Obafemi', 'Robinson', 'Cox', 'Browne', 'Manning', 'Hendrick', "O'Brien"]),
  'أوكرانيا': (['Mykhailo', 'Oleksandr', 'Artem', 'Viktor', 'Andriy', 'Illya', 'Georgiy', 'Vitaliy', 'Anatoliy', 'Taras', 'Ruslan', 'Heorhiy', 'Oleksiy', 'Yaroslav', 'Denys', 'Volodymyr', 'Roman', 'Maksym', 'Serhiy', 'Danylo'],
      ['Mudryk', 'Zinchenko', 'Dovbyk', 'Tsygankov', 'Yarmolenko', 'Zabarnyi', 'Sudakov', 'Mykolenko', 'Malinovskyi', 'Trubin', 'Lunin', 'Bushchan', 'Shaparenko', 'Konoplya', 'Matviyenko', 'Stepanenko', 'Sydorchuk', 'Bondar', 'Kovalenko', 'Shevchenko']),
  'روسيا': (['Artem', 'Aleksandr', 'Fedor', 'Daniil', 'Denis', 'Dmitri', 'Andrei', 'Igor', 'Ivan', 'Nikita', 'Mikhail', 'Kirill', 'Roman', 'Sergei', 'Vladimir', 'Yuri', 'Maksim', 'Pavel', 'Alexei', 'Anton'],
      ['Dzyuba', 'Golovin', 'Smolov', 'Zhirkov', 'Cheryshev', 'Kuzyaev', 'Miranchuk', 'Sobolev', 'Zakharyan', 'Gazinsky', 'Barinov', 'Fomin', 'Kerzhakov', 'Ignatiev', 'Petrov', 'Smirnov', 'Kuznetsov', 'Popov', 'Volkov', 'Sokolov']),
  'اليونان': (['Giorgos', 'Konstantinos', 'Dimitris', 'Vangelis', 'Anastasios', 'Panagiotis', 'Kostas', 'Nikos', 'Christos', 'Manolis', 'Sotiris', 'Stefanos', 'Lazaros', 'Tasos', 'Petros', 'Ioannis', 'Alexandros', 'Fotis', 'Michalis', 'Thanasis'],
      ['Mitroglou', 'Pavlidis', 'Bakasetas', 'Masouras', 'Tzolis', 'Siopis', 'Hatzidiakos', 'Tsimikas', 'Retsos', 'Koulierakis', 'Giakoumakis', 'Limnios', 'Karelis', 'Vlachodimos', 'Papastathopoulos', 'Papadopoulos', 'Nikolaidis', 'Georgiou', 'Dimitriou', 'Pappas']),
  'إيران': (['Mehdi', 'Sardar', 'Alireza', 'Saman', 'Ehsan', 'Majid', 'Saeid', 'Omid', 'Morteza', 'Milad', 'Karim', 'Ramin', 'Voria', 'Shojae', 'Hossein', 'Mohammad', 'Amir', 'Ali', 'Reza', 'Kaveh'],
      ['Taremi', 'Azmoun', 'Jahanbakhsh', 'Ghoddos', 'Hajsafi', 'Ezatolahi', 'Mohammadi', 'Beiranvand', 'Cheshmi', 'Gholizadeh', 'Torabi', 'Hosseini', 'Rezaeian', 'Moharrami', 'Noorollahi', 'Kanaani', 'Ansarifard', 'Karimi', 'Khalilzadeh', 'Ghafouri']),
  'أستراليا': (['Mathew', 'Harry', 'Aaron', 'Jackson', 'Ajdin', 'Craig', 'Jamie', 'Riley', 'Cameron', 'Nestory', 'Garang', 'Connor', 'Kusini', 'Lewis', 'Martin', 'Alex', 'Joel', 'Mitchell', 'Ryan', 'Brandon'],
      ['Ryan', 'Souttar', 'Mooy', 'Irvine', 'Hrustic', 'Goodwin', 'Maclaren', 'McGree', 'Burgess', 'Irankunda', 'Kuol', 'Metcalfe', 'Yengi', 'Miller', 'Boyle', 'Atkinson', 'Duke', 'Behich', 'Leckie', 'Circati']),
};

/// أوزان اختيار الجنسية العشوائية (الأكثر حضوراً في كرة القدم)
const Map<String, int> _w = {
  'إنجلترا': 6, 'فرنسا': 7, 'إسبانيا': 6, 'ألمانيا': 6, 'إيطاليا': 5, 'البرتغال': 4, 'هولندا': 3, 'بلجيكا': 2,
  'البرازيل': 8, 'الأرجنتين': 6, 'أوروغواي': 2, 'كولومبيا': 3, 'المكسيك': 2, 'أمريكا': 2,
  'المغرب': 3, 'الجزائر': 2, 'تونس': 2, 'مصر': 2, 'السعودية': 2, 'السنغال': 3, 'نيجيريا': 4, 'غانا': 2, 'ساحل العاج': 3, 'الكاميرون': 2, 'مالي': 2,
  'اليابان': 2, 'كوريا الجنوبية': 2, 'تركيا': 3, 'كرواتيا': 2, 'صربيا': 2, 'بولندا': 2, 'الدنمارك': 2, 'السويد': 2, 'النرويج': 1,
  'سويسرا': 2, 'النمسا': 1, 'إسكتلندا': 1, 'أيرلندا': 1, 'أوكرانيا': 2, 'روسيا': 2, 'اليونان': 1, 'إيران': 1, 'أستراليا': 1,
};

/// جنسية الفريق الغالبة (غالباً بلد النادي) من لاعبيه الحاليين، أو null
String? dominantNat(Iterable<String?> nats) {
  final c = <String, int>{};
  for (final n in nats) {
    if (n != null && kNames.containsKey(n)) c[n] = (c[n] ?? 0) + 1;
  }
  if (c.isEmpty) return null;
  return c.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// يختار جنسية: غالباً [prefer] (بلد النادي) وأحياناً لاعب أجنبي
String pickNat(Random rng, {String? prefer, double bias = 0.72}) {
  if (prefer != null && kNames.containsKey(prefer) && rng.nextDouble() < bias) return prefer;
  var r = rng.nextInt(_w.values.fold<int>(0, (a, b) => a + b));
  for (final e in _w.entries) {
    r -= e.value;
    if (r < 0) return e.key;
  }
  return 'إنجلترا';
}

/// اسم منطقي للجنسية
String nameFor(Random rng, String nat) {
  final p = kNames[nat] ?? kNames['إنجلترا']!;
  return '${p.$1[rng.nextInt(p.$1.length)]} ${p.$2[rng.nextInt(p.$2.length)]}';
}
