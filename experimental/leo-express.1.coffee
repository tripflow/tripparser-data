module.exports =
  title: 'LEO Express'
  targets:
    itinerary:
      from: [
        'jizdenky@le.cz'
      ]
      match: /děkujeme za nákup u LEO Express a níže posíláme detail Vaší jízdenky/
      scan: (mail, callback, api, current) ->

        data =
          ident:
            'leo-express': mail.text.match(/Objednávka: ([a-z0-9]+)/)[1]
          items: []

        regex = /Jízdenka: ([a-z0-9]+)\nDatum jízdy: (\d{1,2}. \d{1,2}. \d{4})\nČas odjezdu: (\d{2}:\d{2})\nTrasa: (.+) -> (.+)\nSpoj: (.+)\nSedadlo: (.+)/gm
        for conn in mail.text.match(regex)
          m = conn.match(new RegExp regex.source)
          data.items.push 
            ident: m[1]
            date: m[2]
            times:
              std: m[3]
            orig:
              name: m[4]
            dest:
              name: m[5]
            line: m[6]
            seat: m[7]

        callback null, data
