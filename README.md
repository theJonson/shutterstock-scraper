# shutterstock-scraper
Scrape images from shutterstock and upload them to S3.

I'm using this at a client who has a Shutterstock Editorial agreement, and I needed to come up with a way to get the images so they could be pushed to a CMS platform.

Shutterstock has a good API guide at https://api-reference.shutterstock.com/#overview and a test tool at https://api-explorer.shutterstock.com/ I did also have the direct email of a couple of the Shutterstock dev team who I could ask questions to, so that was a plus.

The editorial api endpoints are slightly different to the public ones, but it's possible to use a similar script, as that's what I done to test.

I'm running this on Ubunutu 20.04 as a cron job, you'll also need jq and s3cmd installed. jq to do the json processing, and s3cmd to upload the files.
