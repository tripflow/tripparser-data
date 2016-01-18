module.exports =
  title: 'Ryanair'
  targets:
    itinerary:
      from: [
        'Itinerary@ryanair.com'
      ]
      match: /https:\/\/www.ryanair.com\/([\w_]+)\/?\?cmpid=itinerarymail_([\w_]+)/
      scan: (mail, callback, api, current) ->
        $ = api.cheerio.load mail.html
        base = $ 'center > table > tbody > tr > td'

        ############################
        # BASE INFO                #
        ############################

        payment = $('table:nth-child(5) > tbody > tr > td:nth-child(2) > center > div > table > tbody > tr > td:nth-child(4)', base).text()

        data =
          ident:
            pnr: $('table:nth-child(2) > tbody > tr > td:nth-child(2) > center > div > table > tbody > tr > td:nth-child(1) > div:nth-child(3)', base).text()
          price: api.extractPrice $('table:nth-child(5) > tbody > tr > td:nth-child(2) > center > div > table > tbody > tr > td:nth-child(3) > b', base).text()
          payment:
            card_type: payment.split('\n')[2].trim()
            card_ending: payment.match(/(\d+)$/)[1]
          items: []
          passengers: []
          locale: mail.html.match(current.match)?[1]

        ############################
        # FLIGHTS                  #
        ############################

        getDate = (date) ->
          return api.moment(date, 'ddd, D MMM GG').format('YYYY-MM-DD')

        getGtw = (gtw) ->
          regex = /\(([A-Z]{3})\)/
          m = gtw.match regex
          return {
            iata: m[1]
            name: gtw.replace(regex, '').trim()
          }

        getFlight = (i=2) ->
          flight = $('table:nth-child(3) > tbody > tr > td:nth-child(2) > center > div > table:nth-child('+i+') > tbody > tr > td:nth-child(2) > font b', base).text()
          if !flight then return null
          flBase = $('table:nth-child(3) > tbody > tr > td:nth-child(2) > center > div > table:nth-child('+(i+1)+') > tbody > tr > td', base)
          data.items.push
            flight: flight
            date: getDate $('div:nth-child(1) > table > tbody > tr:nth-child(2) > td:nth-child(2) > b', flBase).text()
            orig: getGtw $('div:nth-child(1) > table > tbody > tr:nth-child(1) > td:nth-child(2) > b', flBase).text()
            dest: getGtw $('div:nth-child(2) > table > tbody > tr:nth-child(1) > td:nth-child(2) > b', flBase).text()
            times:
              std: $('div:nth-child(1) > table > tbody > tr:nth-child(3) > td:nth-child(2) > b', flBase).text()
              sta: $('div:nth-child(2) > table > tbody > tr:nth-child(3) > td:nth-child(2) > b', flBase).text()

        getFlight(2)
        getFlight(11)

        ############################
        # PASSENGERS               #
        ############################

        getPassenger = (i=1) ->
          pg = $('table:nth-child(4) > tbody > tr > td:nth-child(2) > center > div > table:nth-child(2) > tbody > tr:nth-child('+(i+1)+') > td:nth-child(1) > table:nth-child(1) b', base).text()
          if pg then data.passengers.push { name: pg }

        for i in [1..9] then getPassenger(i)
        callback null, data

