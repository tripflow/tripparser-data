module.exports =
  title: 'Wizzair'
  targets:
    itinerary:
      match: /https:\/\/wizzair\.com\/([\w-]+)\/FlightReminder\/([A-Z0-9]+)\//
      scan: (mail, callback, api, current) ->
        $ = api.cheerio.load(mail.html)

        baseMatch = mail.html.match(current.match)
        data =
          ident:
            pnr: baseMatch[2]
            secret: baseMatch[3]
          price: api.extractPrice $('table tr:nth-child(10) > td > table tr > td:nth-child(2) > span').text()
          items: []
          passengers: []
          locale: baseMatch[1]

        # flights

        getTime = (time) ->
          return time.match(/\d{1,2}:\d{2}$/)?[0]

        getGateway = (gw) ->
          gw = gw.trim().match(/(.+)\(([A-Z]{3})\)$/)
          return {
            iata: gw[2]
            name: gw[1].trim()
          }

        getFlight = (i=3) ->
          flightObj = $("table tr:nth-child(5) > td > table tr:nth-child(#{i}) > td > table")
          flightNo = $("table tr:nth-child(5) > td > table tr:nth-child(#{i-1}) > td:nth-child(2)").first().text().trim()
          if i > 3 and not flightNo then return null

          times = $('tr:nth-child(3)', flightObj)

          data.items.push
            ident: flightNo.match(/: ([A-Z0-9]{2,3} \d+)/)[1].replace(/\s/, '')
            date: api.moment($('td:nth-child(1)', times).text(), 'D. M. YYYY').format('YYYY-MM-DD')
            times:
              std: getTime $('td:nth-child(1)', times).text()
              sta: getTime $('td:nth-child(2)', times).text()
            orig: getGateway $("tr:nth-child(2) > td:nth-child(1) > span", flightObj).text()
            dest: getGateway $("tr:nth-child(2) > td:nth-child(2)", flightObj).text()

        getFlight()
        getFlight(5)

        # passengers

        getPassenger = (i=1) ->
          pass = $("table tr:nth-child(4) > td > table tr:nth-child(#{i+2})")

          seats = []
          for si in [1..2] 
            seat = $("td:nth-child(7) div:nth-child(#{si})", pass).text()
            if seat then seats.push seat

          if not $("td:nth-child(1)", pass).text() then return null
          data.passengers.push
            name:
              title: $("td:nth-child(1)", pass).text()
              first: $("td:nth-child(2)", pass).text()
              last: $("td:nth-child(3)", pass).text()
            seats: seats

        for i in [1..10]
          getPassenger(i)


        callback null, data

