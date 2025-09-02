// Swagger documentation for Audit schema and Audit routes

import express from 'express';
import * as controller from '../controllers/auditController';

/**
 * @swagger
 * tags:
 *   name: Audits
 *   description: API for managing audits
 */

// Create swagger schema documentation to be added in .ts file in /** format
/**
 * @swagger
 * components:
 *   schemas:
 *     Audit:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           description: Unique identifier for the audit record.
 *         userId:
 *           type: string
 *           description: Identifier of the user who performed the action.
 *         action:
 *           type: string
 *           description: Description of the action performed.
 *         timestamp:
 *           type: string
 *           format: date-time
 *           description: The date and time when the action was performed.
 *         details:
 *           type: string
 *           description: Additional details about the action performed.
 */

const router = express.Router();
/**
 * @swagger
 * /api/audits:
 *   get:
 *     summary: Returns a list of audits
 *     tags: [Audits]
 *     x-weight: 1
 *     responses:
 *       200:
 *         description: A list of audits
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Audit'
 */
router.get('/', controller.enlist);

/**
 * @swagger
 * /api/audits:
 *   post:
 *     summary: Create a new audit
 *     tags: [Audits]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Audit'
 *     responses:
 *       201:
 *         description: Audit created
 */
router.post('/', controller.create);

export default router;
