// Swagger documentation for Subscription schema and Subscription routes

import express from 'express';
import * as controller from '../controllers/subscriptionController';

/**
 * @swagger
 * tags:
 *   name: Subscriptions
 *   description: API for managing subscriptions
 */
/**
 * @swagger
 * components:
 *   schemas:
 *     Subscription:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         finstitutionId:
 *           type: string
 *           format: uuid
 *         finstrumentId:
 *           type: string
 *           format: uuid
 *         subscriptionDate:
 *           type: string
 *           format: date-time
 *         expirationDate:
 *           type: string
 *           format: date-time
 *         status:
 *           type: string
 *           enum: ['active', 'expired', 'cancelled']
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       required:
 *         - id
 *         - finstitutionId
 *         - finstrumentId
 *         - subscriptionDate
 *         - expirationDate
 *         - status
 *         - createdAt
 *         - updatedAt
 *       example:
 *         id: '123e4567-e89b-12d3-a456-426614174000'
 *         finstitutionId: '123e4567-e89b-12d3-a456-426614174001'
 *         finstrumentId: '123e4567-e89b-12d3-a456-426614174002'
 *         subscriptionDate: '2023-10-01T00:00:00Z'
 *         expirationDate: '2023-11-01T00:00:00Z'
 *         status: 'active'
 *         createdAt: '2023-10-01T00:00:00Z'
 *         updatedAt: '2023-10-01T00:00:00Z'
 */

const router = express.Router();
/**
 * @swagger
 * /api/subscriptions:
 *   get:
 *     summary: Returns a list of subscriptions
 *     tags: [Subscriptions]
 *     responses:
 *       200:
 *         description: A list of subscriptions
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Subscription'
 */
router.get('/', controller.enlist);

/**
 * @swagger
 * /api/subscriptions:
 *   post:
 *     summary: Create a new subscription
 *     tags: [Subscriptions]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Subscription'
 *     responses:
 *       201:
 *         description: Subscription created
 */
router.post('/', controller.create);

export default router;
