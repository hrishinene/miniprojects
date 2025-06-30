// Swagger documentation for Finstrument schema and Finstrument routes

import express from 'express';
import * as controller from '../controllers/finstrumentController';

/**
 * @swagger
 * tags:
 *   name: Finstruments
 *   description: API for managing finstruments
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Finstrument:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           description: Unique identifier for the Finstrument
 *         name:
 *           type: string
 *           description: Name of the financial instrument
 *         type:
 *           type: string
 *           description: Type of the financial instrument (e.g., stock, bond, etc.)
 *         logoUrl:
 *           type: string
 *           description: URL to the logo of the financial instrument
 *         homepageUrl:
 *           type: string
 *           description: URL to the homepage of the financial instrument
 *         healthUrl:
 *           type: string
 *           description: URL to the health information of the financial instrument
 *         secretKey:
 *           type: string
 *           description: Secret key for accessing the financial instrument
 *         configUrl:
 *           type: string
 *           description: URL for configuration settings of the financial instrument
 *         isActive:
 *           type: boolean
 *           description: Indicates if the finstrument is active
 *         createdAt:
 *           type: string
 *           description: Timestamp when the finstrument was created
 *         updatedAt:
 *           type: string
 *           description: Timestamp when the finstrument was last updated
 */

const router = express.Router();

/**
 * @swagger
 * /api/finstruments:
 *   get:
 *     summary: Returns a list of finstruments
 *     tags: [Finstruments]
 *     responses:
 *       200:
 *         description: A list of finstruments
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Finstrument'
 */
router.get('/', controller.enlist);

/**
 * @swagger
 * /api/finstruments:
 *   post:
 *     summary: Create a new finstrument
 *     tags: [Finstruments]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Finstrument'
 *     responses:
 *       201:
 *         description: Finstrument created
 */
router.post('/', controller.create);

export default router;
