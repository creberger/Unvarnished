# The categories players choose from, in display order: (id, name, span, painting ids).
# Every painting belongs to exactly one category; build_content.py checks this.

CATEGORIES = [
    ("renaissance", "Renaissance", "c. 1290–1600", [
        "duccio-madonna", "arnolfini", "descent-from-the-cross", "garden-of-earthly-delights",
        "young-hare", "mona-lisa", "castiglione", "bacchus-and-ariadne", "ambassadors",
        "anguissola-chess", "hunters-in-the-snow", "harvesters", "el-greco-assumption", "view-of-toledo",
    ]),
    ("golden-age", "Golden Age & Baroque", "1600s", [
        "supper-at-emmaus", "artemisia-catherine", "peeters-cheeses", "laughing-cavalier",
        "leyster-self-portrait", "night-watch", "juan-de-pareja", "las-meninas", "view-of-delft",
        "milkmaid", "girl-with-a-pearl-earring", "rembrandt-at-63", "ruysch-flowers",
    ]),
    ("eighteenth-century", "Rococo & Revolution", "1700s", [
        "canaletto-stonemason", "soap-bubbles", "mr-and-mrs-andrews", "the-swing",
        "vigee-le-brun-straw-hat", "death-of-socrates", "manuel-osorio", "death-of-marat",
    ]),
    ("romantic-realist", "Romantics & Realists", "1800–1870", [
        "third-of-may", "wanderer", "raft-of-the-medusa", "hay-wain", "liberty-leading-the-people",
        "burning-of-parliament", "oxbow", "fighting-temeraire", "burial-at-ornans", "ninth-wave",
        "princesse-de-broglie", "horse-fair", "gleaners", "heart-of-the-andes", "max-schmitt",
        "barge-haulers", "whistlers-mother",
    ]),
    ("impressionism", "Impressionism", "1870s–1890s", [
        "impression-sunrise", "the-cradle", "dance-class", "paris-street-rainy-day", "boating-party",
        "folies-bergere", "grande-jatte", "childs-bath", "stacks-of-wheat", "bridge-over-water-lilies",
    ]),
    ("post-impressionism", "After Impressionism", "1880–1900", [
        "madame-x", "spoliarium", "sunflowers", "straw-hat-self-portrait", "the-bedroom",
        "starry-night", "card-players", "moulin-rouge", "surprised", "sleeping-gypsy",
        "the-scream", "where-do-we-come-from", "gulf-stream", "hammershoi-interior",
    ]),
    ("modern", "Modern", "1905–1930", [
        "woman-with-a-hat", "af-klint-adulthood", "the-kiss", "adele-bloch-bauer", "harmony-in-red",
        "street-dresden", "sorolla-seashore", "city-rises", "blue-horses", "gray-tree", "gris-picasso",
        "schiele-physalis", "composition-vii", "black-square", "jack-pine", "the-city-leger",
        "jeanne-hebuterne", "twittering-machine", "several-circles", "mondrian-red-blue-yellow",
    ]),
    ("asia-antiquity", "Asia & Antiquity", "Roman Egypt to Edo Japan", [
        "fayum-portrait", "night-shining-white", "great-wave", "sudden-shower",
    ]),
]
