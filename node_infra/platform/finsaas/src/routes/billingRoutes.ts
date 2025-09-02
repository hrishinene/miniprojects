// Swagger documentation for Billing schema and Billing routes

import express from 'express';
import * as controller from '../controllers/billingController';

/**
 * @swagger
 * tags:
 *   name: Billings
 *   description: API for managing billings
 */
/**
 * @swagger
 * components:
 *   schemas:
 *     Billing:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           description: Unique identifier for the billing record.
 *         finstitutionId:
 *           type: string
 *           description: Identifier of the financial institution associated with the billing.
 *         month:
 *           type: integer
 *           description: Month of the billing record (1-12).
 *         year:
 *           type: integer
 *           description: Year of the billing record.
 *         creditsConsumed:
 *           type: integer
 *           description: Number of credits consumed in the billing period.
 *         status:
 *           type: string
 *           enum: [active, paid, cancelled]
 *           description: Current status of the billing record.
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: The date and time when the billing record was created.
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: The date and time when the billing record was last updated.
 */

const router = express.Router();
/**
 * @swagger
 * /api/billings:
 *   get:
 *     summary: Returns a list of billings
 *     tags: [Billings]
 *     x-weight: 1
 *     responses:
 *       200:
 *         description: A list of billings
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Billing'
 */
router.get('/', controller.enlist);

/**
 * @swagger
 * /api/billings:
 *   post:
 *     summary: Create a new billing
 *     tags: [Billings]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Billing'
 *     responses:
 *       201:
 *         description: Billing created
 */
router.post('/', controller.create);

export default router;
