"use strict";
// Server code from https://github.com/stripe-samples/accept-a-card-payment/tree/master/using-webhooks/server/node-typescript
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const nodemailer_1 = __importDefault(require("nodemailer"));
const dotenv_1 = __importDefault(require("dotenv"));
// Replace if using a different env file or config.
dotenv_1.default.config({ path: './.env' });
const body_parser_1 = __importDefault(require("body-parser"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const stripe_1 = __importDefault(require("stripe"));
const utils_1 = require("./utils");
const firebaseAdmin_1 = require("./firebaseAdmin");
const path_1 = __importDefault(require("path"));
const stripePublishableKey = process.env.STRIPE_PUBLISHABLE_KEY || '';
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || '';
const stripeWebhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
const smtp_mail = process.env.SMTP_MAIL;
const smtp_pass = process.env.SMTP_PASS;
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(body_parser_1.default.json());
app.use(body_parser_1.default.urlencoded({ extended: true }));
app.use((req, res, next) => {
    if (req.originalUrl === '/webhook') {
        next();
    }
    else {
        /* @ts-ignore */
        body_parser_1.default.json()(req, res, next);
    }
});
// tslint:disable-next-line: interface-name
const itemIdToPrice = {
    'id-1': 1400,
    'id-2': 2000,
    'id-3': 3000,
    'id-4': 4000,
    'id-5': 5000,
};
const calculateOrderAmount = (itemIds = ['id-1']) => {
    const total = itemIds
        .map((id) => itemIdToPrice[id])
        .reduce((prev, curr) => prev + curr, 0);
    return total;
};
function getKeys(payment_method) {
    let secret_key = stripeSecretKey;
    let publishable_key = stripePublishableKey;
    switch (payment_method) {
        case 'grabpay':
        case 'fpx':
            publishable_key = process.env.STRIPE_PUBLISHABLE_KEY_MY;
            secret_key = process.env.STRIPE_SECRET_KEY_MY;
            break;
        case 'au_becs_debit':
            publishable_key = process.env.STRIPE_PUBLISHABLE_KEY_AU;
            secret_key = process.env.STRIPE_SECRET_KEY_AU;
            break;
        case 'oxxo':
            publishable_key = process.env.STRIPE_PUBLISHABLE_KEY_MX;
            secret_key = process.env.STRIPE_SECRET_KEY_MX;
            break;
        case 'wechat_pay':
            publishable_key = process.env.STRIPE_PUBLISHABLE_KEY_WECHAT;
            secret_key = process.env.STRIPE_SECRET_KEY_WECHAT;
            break;
        case 'paypal':
            publishable_key = process.env.STRIPE_PUBLISHABLE_KEY_UK;
            secret_key = process.env.STRIPE_SECRET_KEY_UK;
            break;
        default:
            publishable_key = process.env.STRIPE_PUBLISHABLE_KEY;
            secret_key = process.env.STRIPE_SECRET_KEY;
    }
    return { secret_key, publishable_key };
}
// Set the view engine to ejs
app.set('view engine', 'ejs');
app.set('views', path_1.default.resolve(__dirname, '../views'));
// Verify endpoint
app.get('/verify', (req, res) => {
    const name = req.query.name;
    const email = req.query.email;
    const phone = req.query.phone;
    const company = req.query.company;
    const address = JSON.parse(req.query.address);
    res.render('verify', { name, email, phone, company, address });
});
app.post('/approve', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const name = req.body.name;
    const email = req.body.email;
    const phone = req.body.phone;
    const company = req.body.company;
    const address = JSON.parse(req.body.address);
    if (!name || !email || !phone || !company || !address) {
        return res.status(400).send('All fields are required');
    }
    try {
        // Create a new user in Firebase Auth
        const userRecord = yield firebaseAdmin_1.admin.auth().createUser({
            email: email,
            emailVerified: false,
            password: 'defaultpassword',
            displayName: name,
            disabled: false,
        });
        // Add user information to Firestore
        yield firebaseAdmin_1.db.collection('user').doc(userRecord.uid).set({
            phone: phone,
            company: company,
            address: address,
            role: 'owner',
            franchiseID: userRecord.uid, // Adjust this as needed
        });
        // Add documents to other collections
        const collections = ['franchise', 'product', 'purchase', 'sales', 'store'];
        const batch = firebaseAdmin_1.db.batch();
        collections.forEach((collection) => {
            const docRef = firebaseAdmin_1.db.collection(collection).doc(userRecord.uid);
            batch.set(docRef, {}); // Add any default data here if needed
        });
        // Commit the batch
        yield batch.commit();
        // Create the 'list' subcollection in each document
        yield Promise.all(collections.map((collection) => firebaseAdmin_1.db.collection(collection).doc(userRecord.uid).collection('list').add({}) // Add any default data here if needed
        ));
        yield firebaseAdmin_1.db
            .collection("product")
            .doc(userRecord.uid)
            .collection("category"); // Add any default data here if needed
        res.status(200).send('User approved and registered successfully');
    }
    catch (error) {
        console.error('Error approving user:', error);
        res.status(500).send('Internal Server Error');
    }
}));
app.post('/send-verification-email', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email, displayName, phone, company, address } = req.body;
    if (!email || !displayName || !phone || !company || !address) {
        return res.status(400).send('All fields are required');
    }
    const link = `https://franchise-management-server.vercel.app/verify?email=${encodeURIComponent(email)}&name=${encodeURIComponent(displayName)}&phone=${encodeURIComponent(phone)}&company=${encodeURIComponent(company)}&address=${encodeURIComponent(JSON.stringify(address))}`;
    const transporter = nodemailer_1.default.createTransport({
        service: 'gmail',
        auth: {
            user: smtp_mail,
            pass: smtp_pass,
        },
    });
    const mailOptions = {
        from: `"Franchise Manager" <${smtp_mail}>`,
        to: email,
        subject: 'Account Verification',
        text: `Please verify your account by clicking the link: ${link}`,
    };
    try {
        yield transporter.sendMail(mailOptions);
        res.status(200).send('Verification email sent successfully');
    }
    catch (error) {
        console.error('Error sending email:', error);
        res.status(500).send('Error sending email');
    }
}));
app.get('/stripe-key', (req, res) => {
    const { publishable_key } = getKeys(req.query.paymentMethod);
    return res.send({ publishableKey: publishable_key });
});
app.post('/create-payment-intent', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email, items, currency, request_three_d_secure, payment_method_types = [], client = 'ios', } = req.body;
    const { secret_key } = getKeys(payment_method_types[0]);
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const customer = yield stripe.customers.create({ email });
    // Create a PaymentIntent with the order amount and currency.
    const params = {
        amount: calculateOrderAmount(items),
        currency,
        customer: customer.id,
        payment_method_options: {
            card: {
                request_three_d_secure: request_three_d_secure || 'automatic',
            },
            sofort: {
                preferred_language: 'en',
            },
            wechat_pay: {
                app_id: 'wx65907d6307c3827d',
                client: client,
            },
        },
        payment_method_types: payment_method_types,
    };
    try {
        const paymentIntent = yield stripe.paymentIntents.create(params);
        // Send publishable key and PaymentIntent client_secret to client.
        return res.send({
            clientSecret: paymentIntent.client_secret,
        });
    }
    catch (error) {
        return res.send({
            error: error.raw.message,
        });
    }
}));
app.post('/create-payment-intent-with-payment-method', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { items, currency, request_three_d_secure, email, } = req.body;
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const customers = yield stripe.customers.list({
        email,
    });
    // The list all Customers endpoint can return multiple customers that share the same email address.
    // For this example we're taking the first returned customer but in a production integration
    // you should make sure that you have the right Customer.
    if (!customers.data[0]) {
        return res.send({
            error: 'There is no associated customer object to the provided e-mail',
        });
    }
    // List the customer's payment methods to find one to charge
    const paymentMethods = yield stripe.paymentMethods.list({
        customer: customers.data[0].id,
        type: 'card',
    });
    if (!paymentMethods.data[0]) {
        return res.send({
            error: `There is no associated payment method to the provided customer's e-mail`,
        });
    }
    const params = {
        amount: calculateOrderAmount(items),
        currency,
        payment_method_options: {
            card: {
                request_three_d_secure: request_three_d_secure || 'automatic',
            },
        },
        payment_method: paymentMethods.data[0].id,
        customer: customers.data[0].id,
    };
    const paymentIntent = yield stripe.paymentIntents.create(params);
    // Send publishable key and PaymentIntent client_secret to client.
    return res.send({
        clientSecret: paymentIntent.client_secret,
        paymentMethodId: paymentMethods.data[0].id,
    });
}));
app.post('/pay-without-webhooks', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { paymentMethodId, paymentIntentId, items, currency, useStripeSdk, cvcToken, email, } = req.body;
    const orderAmount = calculateOrderAmount(items);
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    try {
        if (cvcToken && email) {
            const customers = yield stripe.customers.list({
                email,
            });
            // The list all Customers endpoint can return multiple customers that share the same email address.
            // For this example we're taking the first returned customer but in a production integration
            // you should make sure that you have the right Customer.
            if (!customers.data[0]) {
                return res.send({
                    error: 'There is no associated customer object to the provided e-mail',
                });
            }
            const paymentMethods = yield stripe.paymentMethods.list({
                customer: customers.data[0].id,
                type: 'card',
            });
            if (!paymentMethods.data[0]) {
                return res.send({
                    error: `There is no associated payment method to the provided customer's e-mail`,
                });
            }
            const params = {
                amount: orderAmount,
                confirm: true,
                confirmation_method: 'manual',
                currency,
                payment_method: paymentMethods.data[0].id,
                payment_method_options: {
                    card: {
                        cvc_token: cvcToken,
                    },
                },
                use_stripe_sdk: useStripeSdk,
                customer: customers.data[0].id,
                return_url: 'stripe-example://stripe-redirect',
            };
            const intent = yield stripe.paymentIntents.create(params);
            return res.send((0, utils_1.generateResponse)(intent));
        }
        else if (paymentMethodId) {
            // Create new PaymentIntent with a PaymentMethod ID from the client.
            const params = {
                amount: orderAmount,
                confirm: true,
                confirmation_method: 'manual',
                currency,
                payment_method: paymentMethodId,
                // If a mobile client passes `useStripeSdk`, set `use_stripe_sdk=true`
                // to take advantage of new authentication features in mobile SDKs.
                use_stripe_sdk: useStripeSdk,
                return_url: 'stripe-example://stripe-redirect',
            };
            const intent = yield stripe.paymentIntents.create(params);
            // After create, if the PaymentIntent's status is succeeded, fulfill the order.
            return res.send((0, utils_1.generateResponse)(intent));
        }
        else if (paymentIntentId) {
            // Confirm the PaymentIntent to finalize payment after handling a required action
            // on the client.
            const intent = yield stripe.paymentIntents.confirm(paymentIntentId);
            // After confirm, if the PaymentIntent's status is succeeded, fulfill the order.
            return res.send((0, utils_1.generateResponse)(intent));
        }
        return res.sendStatus(400);
    }
    catch (e) {
        // Handle "hard declines" e.g. insufficient funds, expired card, etc
        // See https://stripe.com/docs/declines/codes for more.
        return res.send({ error: e.message });
    }
}));
app.post('/create-setup-intent', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email, payment_method_types = [], } = req.body;
    const { secret_key } = getKeys(payment_method_types[0]);
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const customer = yield stripe.customers.create({ email });
    const payPalIntentPayload = {
        return_url: 'https://example.com/setup/complete',
        payment_method_options: { paypal: { currency: 'eur' } },
        payment_method_data: { type: 'paypal' },
        mandate_data: {
            customer_acceptance: {
                type: 'online',
                online: {
                    ip_address: '1.1.1.1',
                    user_agent: 'test-user-agent',
                },
            },
        },
        confirm: true,
    };
    //@ts-ignore
    const setupIntent = yield stripe.setupIntents.create(Object.assign({ customer: customer.id, payment_method_types }, ((payment_method_types === null || payment_method_types === void 0 ? void 0 : payment_method_types.includes('paypal')) ? payPalIntentPayload : {})));
    // Send publishable key and SetupIntent details to client
    return res.send({
        publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
        clientSecret: setupIntent.client_secret,
    });
}));
// Expose a endpoint as a webhook handler for asynchronous events.
// Configure your webhook in the stripe developer dashboard:
// https://dashboard.stripe.com/test/webhooks
app.post('/webhook', 
// Use body-parser to retrieve the raw body as a buffer.
/* @ts-ignore */
body_parser_1.default.raw({ type: 'application/json' }), (req, res) => {
    // Retrieve the event by verifying the signature using the raw body and secret.
    let event;
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    // console.log('webhook!', req);
    try {
        event = stripe.webhooks.constructEvent(req.body, req.headers['stripe-signature'] || [], stripeWebhookSecret);
    }
    catch (err) {
        console.log(`⚠️  Webhook signature verification failed.`);
        return res.sendStatus(400);
    }
    // Extract the data from the event.
    const data = event.data;
    const eventType = event.type;
    if (eventType === 'payment_intent.succeeded') {
        // Cast the event into a PaymentIntent to make use of the types.
        const pi = data.object;
        // Funds have been captured
        // Fulfill any orders, e-mail receipts, etc
        // To cancel the payment after capture you will need to issue a Refund (https://stripe.com/docs/api/refunds).
        console.log(`🔔  Webhook received: ${pi.object} ${pi.status}!`);
        console.log('💰 Payment captured!');
    }
    if (eventType === 'payment_intent.payment_failed') {
        // Cast the event into a PaymentIntent to make use of the types.
        const pi = data.object;
        console.log(`🔔  Webhook received: ${pi.object} ${pi.status}!`);
        console.log('❌ Payment failed.');
    }
    if (eventType === 'setup_intent.setup_failed') {
        console.log(`🔔  A SetupIntent has failed the to setup a PaymentMethod.`);
    }
    if (eventType === 'setup_intent.succeeded') {
        console.log(`🔔  A SetupIntent has successfully setup a PaymentMethod for future use.`);
    }
    if (eventType === 'setup_intent.created') {
        const setupIntent = data.object;
        console.log(`🔔  A new SetupIntent is created. ${setupIntent.id}`);
    }
    return res.sendStatus(200);
});
// An endpoint to charge a saved card
// In your application you may want a cron job / other internal process
app.post('/charge-card-off-session', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    let paymentIntent, customer;
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    try {
        // You need to attach the PaymentMethod to a Customer in order to reuse
        // Since we are using test cards, create a new Customer here
        // You would do this in your payment flow that saves cards
        customer = yield stripe.customers.list({
            email: req.body.email,
        });
        // List the customer's payment methods to find one to charge
        const paymentMethods = yield stripe.paymentMethods.list({
            customer: customer.data[0].id,
            type: 'card',
        });
        // Create and confirm a PaymentIntent with the order amount, currency,
        // Customer and PaymentMethod ID
        paymentIntent = yield stripe.paymentIntents.create({
            amount: calculateOrderAmount(),
            currency: 'usd',
            payment_method: paymentMethods.data[0].id,
            customer: customer.data[0].id,
            off_session: true,
            confirm: true,
        });
        return res.send({
            succeeded: true,
            clientSecret: paymentIntent.client_secret,
            publicKey: stripePublishableKey,
        });
    }
    catch (err) {
        if (err.code === 'authentication_required') {
            // Bring the customer back on-session to authenticate the purchase
            // You can do this by sending an email or app notification to let them know
            // the off-session purchase failed
            // Use the PM ID and client_secret to authenticate the purchase
            // without asking your customers to re-enter their details
            return res.send({
                error: 'authentication_required',
                paymentMethod: err.raw.payment_method.id,
                clientSecret: err.raw.payment_intent.client_secret,
                publicKey: stripePublishableKey,
                amount: calculateOrderAmount(),
                card: {
                    brand: err.raw.payment_method.card.brand,
                    last4: err.raw.payment_method.card.last4,
                },
            });
        }
        else if (err.code) {
            // The card was declined for other reasons (e.g. insufficient funds)
            // Bring the customer back on-session to ask them for a new payment method
            return res.send({
                error: err.code,
                clientSecret: err.raw.payment_intent.client_secret,
                publicKey: stripePublishableKey,
            });
        }
        else {
            console.log('Unknown error occurred', err);
            return res.sendStatus(500);
        }
    }
}));
// This example sets up an endpoint using the Express framework.
// Watch this video to get started: https://youtu.be/rPR2aJ6XnAc.
app.post('/payment-sheet', (_, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const customers = yield stripe.customers.list();
    // Here, we're getting latest customer only for example purposes.
    const customer = customers.data[0];
    if (!customer) {
        return res.send({
            error: 'You have no customer created',
        });
    }
    const ephemeralKey = yield stripe.ephemeralKeys.create({ customer: customer.id }, { apiVersion: '2023-08-16' });
    const paymentIntent = yield stripe.paymentIntents.create({
        amount: 5099,
        currency: 'eur',
        customer: customer.id,
        // Edit the following to support different payment methods in your PaymentSheet
        // Note: some payment methods have different requirements: https://stripe.com/docs/payments/payment-methods/integration-options
        payment_method_types: [
            'card',
            // 'ideal',
            // 'sepa_debit',
            // 'sofort',
            // 'bancontact',
            // 'p24',
            // 'giropay',
            // 'eps',
            // 'afterpay_clearpay',
            // 'klarna',
            // 'us_bank_account',
        ],
    });
    return res.json({
        paymentIntent: paymentIntent.client_secret,
        ephemeralKey: ephemeralKey.secret,
        customer: customer.id,
    });
}));
app.post('/payment-sheet-subscription', (_, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const customers = yield stripe.customers.list();
    // Here, we're getting latest customer only for example purposes.
    const customer = customers.data[0];
    if (!customer) {
        return res.send({
            error: 'You have no customer created',
        });
    }
    const ephemeralKey = yield stripe.ephemeralKeys.create({ customer: customer.id }, { apiVersion: '2023-08-16' });
    const subscription = yield stripe.subscriptions.create({
        customer: customer.id,
        items: [{ price: 'price_1L3hcFLu5o3P18Zp9GDQEnqe' }],
        trial_period_days: 3,
    });
    if (typeof subscription.pending_setup_intent === 'string') {
        const setupIntent = yield stripe.setupIntents.retrieve(subscription.pending_setup_intent);
        return res.json({
            setupIntent: setupIntent.client_secret,
            ephemeralKey: ephemeralKey.secret,
            customer: customer.id,
        });
    }
    else {
        throw new Error('Expected response type string, but received: ' +
            typeof subscription.pending_setup_intent);
    }
}));
app.post('/ephemeral-key', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: req.body.apiVersion,
        typescript: true,
    });
    try {
        let key = yield stripe.ephemeralKeys.create({ issuing_card: req.body.issuingCardId }, { apiVersion: req.body.apiVersion });
        return res.send(key);
    }
    catch (e) {
        console.log(e);
        return res.send({ error: e });
    }
}));
app.post('/issuing-card-details', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    try {
        let card = yield stripe.issuing.cards.retrieve(req.body.id);
        if (!card) {
            console.log('No card with that ID exists.');
            return res.send({ error: 'No card with that ID exists.' });
        }
        else {
            return res.send(card);
        }
    }
    catch (e) {
        console.log(e);
        return res.send({ error: e });
    }
}));
app.post('/financial-connections-sheet', (_, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const account = yield stripe.accounts.create({
        country: 'US',
        type: 'custom',
        capabilities: {
            card_payments: { requested: true },
            transfers: { requested: true },
        },
    });
    const session = yield stripe.financialConnections.sessions.create({
        account_holder: { type: 'account', account: account.id },
        filters: { countries: ['US'] },
        permissions: ['ownership', 'payment_method'],
    });
    return res.send({ clientSecret: session.client_secret });
}));
app.post('/payment-intent-for-payment-sheet', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    try {
        const paymentIntent = yield stripe.paymentIntents.create({
            amount: 5099,
            currency: 'usd',
            payment_method: req.body.paymentMethodId,
            customer: req.body.customerId,
        });
        return res.send({ clientSecret: paymentIntent.client_secret });
    }
    catch (e) {
        return res.send({ error: e });
    }
}));
app.post('/create-checkout-session', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    console.log(`Called /create-checkout-session`);
    const { port, } = req.body;
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    var effectivePort = port !== null && port !== void 0 ? port : 8080;
    // Use an existing Customer ID if this is a returning customer.
    const customer = yield stripe.customers.create();
    // Use the same version as the SDK
    const ephemeralKey = yield stripe.ephemeralKeys.create({ customer: customer.id }, { apiVersion: '2020-08-27' });
    const setupIntent = yield stripe.setupIntents.create({
        customer: customer.id,
    });
    res.json({
        customer: customer.id,
        ephemeralKeySecret: ephemeralKey.secret,
        setupIntent: setupIntent.client_secret,
    });
}));
app.post('/customer-sheet', (_, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    // Use an existing Customer ID if this is a returning customer.
    const customer = yield stripe.customers.create();
    // Use the same version as the SDK
    const ephemeralKey = yield stripe.ephemeralKeys.create({ customer: customer.id }, { apiVersion: '2020-08-27' });
    const setupIntent = yield stripe.setupIntents.create({
        customer: customer.id,
    });
    res.json({
        customer: customer.id,
        ephemeralKeySecret: ephemeralKey.secret,
        setupIntent: setupIntent.client_secret,
    });
}));
app.post('/fetch-payment-methods', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const paymentMethods = yield stripe.customers.listPaymentMethods(req.body.customerId);
    res.json({
        paymentMethods: paymentMethods.data,
    });
}));
app.post('/attach-payment-method', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    console.log({ customer: req.body.customerId });
    const paymentMethod = yield stripe.paymentMethods.attach(req.body.paymentMethodId, { customer: req.body.customerId });
    console.log('got here');
    res.json({
        paymentMethod,
    });
}));
app.post('/detach-payment-method', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const paymentMethod = yield stripe.paymentMethods.detach(req.body.paymentMethodId);
    res.json({
        paymentMethod,
    });
}));
// Mocks a Database. In your code, you should use a persistent database.
let savedPaymentOptions = new Map();
app.post('/set-payment-option', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    savedPaymentOptions.set(req.body.customerId, req.body.paymentOption);
    res.json({});
}));
app.post('/get-payment-option', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { secret_key } = getKeys();
    const stripe = new stripe_1.default(secret_key, {
        apiVersion: '2023-08-16',
        typescript: true,
    });
    const customerPaymentOption = savedPaymentOptions.get(req.body.customerId);
    res.json({
        savedPaymentOption: customerPaymentOption !== null && customerPaymentOption !== void 0 ? customerPaymentOption : null,
    });
    const session = yield stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        line_items: [
            {
                price_data: {
                    currency: 'usd',
                    product_data: {
                        name: 'Stubborn Attachments',
                        images: ['https://i.imgur.com/EHyR2nP.png'],
                    },
                    unit_amount: 2000,
                },
                quantity: 1,
            },
        ],
        mode: 'payment',
        success_url: `https://checkout.stripe.dev/success`,
        cancel_url: `https://checkout.stripe.dev/cancel`,
    });
    return res.json({ id: session.id });
}));
app.listen(4242, () => console.log(`Node server listening on port ${4242}!`));
