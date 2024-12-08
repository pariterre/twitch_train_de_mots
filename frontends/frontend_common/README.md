# CONTEXTE
L'extension est un add-on de l'application "Train de Mots" (https://traindemots.pariterre.net). Train de Mots est un jeu collaboratif similaire au célèbre jeu du baccalauréat. À partir d'un ensemble de lettres, l'objectif est de trouver collectivement suffisamment de mots pour avancer dans le jeu, à raison de manches de deux minutes. Ce jeu est à la fois coopératif et compétitif : les joueurs et joueuses doivent non seulement contribuer ensemble à atteindre le plus de "stations" possibles, mais aussi chercher à maximiser leur score individuel. Un joueur ou une joueuse peut marquer des points en découvrant un nouveau mot ou en volant le mot d'un autre participant. Cependant, le vol pénalise l'équipe entière, car le train recule d'autant de points que le vol a rapporté.


# DESCRIPTION
L'extension permet d'ajouter des interactions supplémentaires qui influencent directement le déroulement du jeu. Ces interactions sont les suivantes :

- Pardon : permet de redonner les points à l'équipe après un vol de mot. Seule la personne volée peut utiliser cette option.
- Boost : double les points récoltés. Pour activer cette option, trois joueurs ou joueuses doivent demander simultanément le boost.
- Féliciter (utilise des bits) : envoie des feux d'artifice à l'écran pour encourager ses coéquipiers. Cette option n'est disponible qu'à partir de la station 10.
- Frapper le Grand Coup (utilise des bits) : propose un quitte ou double. Si l'équipe parvient à passer plus de 3 stations, elle avance de 6 stations d'un coup, sinon la partie est perdue. Cette option devient disponible de manière aléatoire à partir de la station 15.


# UTILISATION

1. L'extension se connecte automatiquement à l'EBS. Tant que le streamer ou la streameuse ne s'est pas connecteé au Train de Mots (via le site web), l'extension affiche une page d'accueil où les spectateurs ne peuvent pas interagir.
2. Dès que le streamer ou la streameuse se connecte, l'extension affiche une salle d'attente, identique à celle qui apparaît entre chaque manche. À ce moment, l'extension ne permet pas encore d'interaction.
3. Lorsque le streamer ou la streameuse démarre une manche, l'écran affiche les boutons PARDON et BOOST. Le bouton PARDON n'est utilisable que si le spectateur ou la spectatrice s'est fait voler un mot et que des pardons sont encore disponibles pour l'équipe. Le bouton BOOST est utilisable seulement si l'équipe dispose encore de boosts.
4. À la fin de chaque manche, la salle d'attente (voir étape 2) réapparaît. Si l'équipe a atteint au moins la 10e station, le bouton FÉLICITER s'affiche, permettant aux spectateurs de dépenser des bits pour encourager l'équipe. Si l'équipe atteint la 15e station et que le jeu détermine qu'il est possible de tenter Le Grand Coup, ce bouton remplace celui de FÉLICITER.