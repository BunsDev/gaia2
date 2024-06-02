const ethers = await import("npm:ethers@6.10.0");
if (!secrets.soccerApiKey) {
    throw Error("Sportsdata.io API KEY is required")
}

// Execute the API request (Promise)
// const apiResponse = await Functions.makeHttpRequest({
const response = await Functions.makeHttpRequest({
    url: `https://api-football-v1.p.rapidapi.com/v3/fixtures?date=2024-03-02&league=39&season=2023`,
    headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': secrets.soccerApiKey,
    },
}
)

const allMatches = response.data.response;
// console.log(allMatches)
// Lists to hold the extracted data
const fixtureIdList = [];
const timestampList = [];

allMatches.forEach(fixtureData => {
    fixtureIdList.push(fixtureData.fixture.id);
    timestampList.push(fixtureData.fixture.timestamp);

});

// Output the lists
console.log("Fixture ID List:", fixtureIdList);
console.log("Timestamp List:", timestampList);


// const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
//   ["uint256", "uint256", "uint8", "string"],
//   [dataFeedResponse.answer, dataFeedResponse.updatedAt, decimals, description]
// );

const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
    ["uint32[]", "uint32[]"],
    [fixtureIdList, timestampList]);
// return the encoded data as Uint8Array
// return ethers.getBytes(encoded);

return ethers.getBytes(encoded);