module.exports =
  title: 'Meinfernbus Flixbus'
  targets:
    itinerary:
      from: [
        'service@flixbus.de'
        'bestaetigung@meinfernbus.de'
      ]
      scan: (mail, callback, api, current) ->
        pdf = mail.attachments[2]

        api.tmp.file (err, path, fd, tmpCleanup) ->
          # save pdf to local
          api.fs.writeFileSync path, pdf.content

          # extract PDF
          extract =
            number: { x: 60, y: 155, W: 270, H: 35, r: 150, f: 1, l: 1 }
            date: { x: 370, y: 90, W: 400, H: 50, r: 150, f: 1, l: 1 }
            route: { x: 370, y: 140, W: 400, H: 260, r: 150, f: 1, l: 1 }
            passengers: { x: 815, y: 200, W: 400, H: 900, r: 150, f: 1, l: 1 }

          api.extractPDF path, extract, (err, ext) ->

            sanitize = (txt) ->
              txt.replace(/\n/g, ' ').trim()

            data =
              ident:
                number: ext.number.replace('#', '')
              items: []
              passengers: []
              extracted: ext

            # passengers
            for pass in ext.passengers.split('\n\n')
              if pass.match('\n')
                splitted = pass.split('\n')
                pass = splitted[0]
                phone = splitted[1]
              else
                phone = undefined
              data.passengers.push
                name: pass
                phone: phone
          
            # route
            routeMatch = ext.route.match(/.+ (\d{2}:\d{2})([\s\S]+)\n.+ (\d+) (.+)([\s\S]+).+ (\d{2}:\d{2})([\s\S]+)/)
            console.log routeMatch

            data.items.push
              date: ext.date
              line: sanitize routeMatch[3]
              time:
                std: routeMatch[1]
                sta: routeMatch[6]
              orig:
                name: sanitize routeMatch[2]
              dest:
                name: sanitize routeMatch[7]

            callback null, data
            tmpCleanup()

