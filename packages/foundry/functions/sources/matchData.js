const { SecretsManager } = require("@chainlink/functions-toolkit");

const matchResult = await Functions.makeHttpRequest({
    url: `https://api-football-v1.p.rapidapi.com/v3/timezone`,
    headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': SecretsManager.getSecret("RAPIDAPI_KEY"),
    },
}
)

const [response] = await Promise.all([matchResult])
const [results] = response.results
console.log("the number of :, ", results)