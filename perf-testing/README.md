To run the perf test

Set the `ANALYTICKIT_URL` and `API_KEY` env variables (the latter can be found in Analytickit project/settings page), e.g.

```
export ANALYTICKIT_URL="https://analytickit.click"
export ANALYTICKIT_URL="http://localhost:8000"
export API_KEY='ws6xnNaSGqAbY07-Q0SVJPJrhfGtpPKSecKDiBn97ps'
```

Run k6 ([docs](https://k6.io/docs/)).

```
k6 run k6-capture-events.js
```

Sleep time can be customized to add more load.

```
CE_SLEEP=0.1 k6 run k6-capture-events.js
```

There's no verification here that Analytickit got the data, consider checking insights through the Analytickit UI.
