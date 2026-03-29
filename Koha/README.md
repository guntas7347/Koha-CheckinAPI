# Koha Checkin API Plugin

Simple API plugin for Koha to perform item check-ins via REST.

## What it does

Provides a `/checkin` API endpoint that allows you to return (check-in) items using barcode and branch code.
Handles errors (invalid barcode, server issues) and returns structured JSON responses.

## Installation

1. Clone this repository
2. Zip the `Koha` directory into a `.kpz` file
3. Go to **Koha Admin Panel → Plugins**
4. Upload the `.kpz` file
5. Enable the plugin

## Notes

* If you hit a **404 HTML page**, the plugin is not installed properly
* If API intermittently returns 404 HTML, restart Plack:

```
docker exec -it kohadev-koha-1 koha-plack --restart kohadev
```

Then refresh

## Author

Guntas Singh
https://guntassandhu.com
https://github.com/guntas7347
