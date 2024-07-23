const express = require('express');
const app = express();
const stripe = require('stripe')('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'); // Replace with your Stripe secret key
const bodyParser = require('body-parser');

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

const PORT = process.env.PORT || 4242;
app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));