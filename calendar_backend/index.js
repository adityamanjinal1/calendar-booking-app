const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const { Mutex } = require('async-mutex');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

let bookings = [];
const bookingMutex = new Mutex();

// Swagger setup
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Calendar Booking API',
      version: '1.1.0',
      description: 'API to manage room bookings with conflict validation and CRUD operations.',
    },
    servers: [{ url: 'http://localhost:3000' }],
  },
  apis: ['./index.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

/**
 * @swagger
 * /bookings:
 *   get:
 *     summary: Get all bookings
 *     responses:
 *       200:
 *         description: Returns a list of all bookings
 */
app.get('/bookings', (req, res) => {
  res.json(bookings);
});

/**
 * @swagger
 * /bookings/{id}:
 *   get:
 *     summary: Get a booking by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Booking found
 *       404:
 *         description: Booking not found
 */
app.get('/bookings/:id', (req, res) => {
  const booking = bookings.find(b => b.id === req.params.id);
  if (!booking) return res.status(404).json({ error: 'Booking not found' });
  res.json(booking);
});

/**
 * @swagger
 * /bookings:
 *   post:
 *     summary: Create a new booking
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: string
 *                 example: user-123
 *               startTime:
 *                 type: string
 *                 format: date-time
 *                 example: 2025-03-01T10:00:00
 *               endTime:
 *                 type: string
 *                 format: date-time
 *                 example: 2025-03-01T11:00:00
 *     responses:
 *       201:
 *         description: Booking created
 *       400:
 *         description: Invalid input
 *       409:
 *         description: Booking time conflict
 */
app.post('/bookings', async (req, res) => {
  const release = await bookingMutex.acquire();
  try {
    const { userId, startTime, endTime } = req.body;

    if (!userId || !startTime || !endTime) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const parsedStart = new Date(startTime);
    const parsedEnd = new Date(endTime);
    if (isNaN(parsedStart) || isNaN(parsedEnd)) {
      return res.status(400).json({ error: 'Invalid date format' });
    }
    if (parsedStart >= parsedEnd) {
      return res.status(400).json({ error: 'Start time must be before end time' });
    }

    const hasConflict = bookings.some(b => {
      const bStart = new Date(b.startTime);
      const bEnd = new Date(b.endTime);
      return parsedStart < bEnd && parsedEnd > bStart;
    });

    if (hasConflict) return res.status(409).json({ error: 'Booking conflict' });

    const newBooking = {
      id: uuidv4(),
      userId,
      startTime: parsedStart.toISOString().replace('Z', ''),
      endTime: parsedEnd.toISOString().replace('Z', ''),
    };

    bookings.push(newBooking);
    res.status(201).json(newBooking);
  } finally {
    release();
  }
});

/**
 * @swagger
 * /bookings/{id}:
 *   put:
 *     summary: Update an existing booking
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: string
 *               startTime:
 *                 type: string
 *               endTime:
 *                 type: string
 *     responses:
 *       200:
 *         description: Booking updated
 *       400:
 *         description: Invalid input
 *       404:
 *         description: Booking not found
 *       409:
 *         description: Conflict with another booking
 */
app.put('/bookings/:id', async (req, res) => {
  const release = await bookingMutex.acquire();
  try {
    const bookingId = req.params.id;
    const { userId, startTime, endTime } = req.body;

    const index = bookings.findIndex(b => b.id === bookingId);
    if (index === -1) return res.status(404).json({ error: 'Booking not found' });

    const parsedStart = new Date(startTime);
    const parsedEnd = new Date(endTime);
    if (isNaN(parsedStart) || isNaN(parsedEnd)) {
      return res.status(400).json({ error: 'Invalid date format' });
    }
    if (parsedStart >= parsedEnd) {
      return res.status(400).json({ error: 'Start time must be before end time' });
    }

    const hasConflict = bookings.some(b => {
      if (b.id === bookingId) return false;
      const bStart = new Date(b.startTime);
      const bEnd = new Date(b.endTime);
      return parsedStart < bEnd && parsedEnd > bStart;
    });

    if (hasConflict) return res.status(409).json({ error: 'Booking conflict' });

    bookings[index] = {
      ...bookings[index],
      userId: userId || bookings[index].userId,
      startTime: parsedStart.toISOString().replace('Z', ''),
      endTime: parsedEnd.toISOString().replace('Z', ''),
    };

    res.json(bookings[index]);
  } finally {
    release();
  }
});

/**
 * @swagger
 * /bookings/{id}:
 *   delete:
 *     summary: Delete a booking by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Booking deleted
 *       404:
 *         description: Booking not found
 */
app.delete('/bookings/:id', async (req, res) => {
  const release = await bookingMutex.acquire();
  try {
    const bookingId = req.params.id;
    const index = bookings.findIndex(b => b.id === bookingId);
    if (index === -1) return res.status(404).json({ error: 'Booking not found' });

    const deleted = bookings.splice(index, 1);
    res.json({ message: 'Booking deleted', deleted: deleted[0] });
  } finally {
    release();
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ API running at http://localhost:${PORT}`);
  console.log(`📚 Swagger docs available at http://localhost:${PORT}/api-docs`);
});
