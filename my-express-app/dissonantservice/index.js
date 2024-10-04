const express = require('express');
const app = express();
const stripe = require('stripe')('sk_test_51ODzOACnvJAFsDZ0A1WjKAJOi3ZmTxilTnGkHIaFBumhwVZwufnzLRLeKMyG2z6HHozAtPE3xPjdXkunTREhBZSY00qaH93Ib3'); // Replace with your Stripe secret key
const bodyParser = require('body-parser');
const serverless = require('serverless-http');

app.use(bodyParser.json());

app.post('/create-payment-intent', async (req, res) => {
  const { amount } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'usd',
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).send(error.message);
  }
});

module.exports.handler = serverless(app);