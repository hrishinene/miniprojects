// Swagger documentation for Finstitution schema and Finstitution routes

import express from 'express';
import * as controller from '../controllers/finstitutionController';

/**
 * @swagger
 * tags:
 *   name: Finstitutions
 *   description: API for managing finstitutions
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Finstitution:
 *       type: object
 *       properties:
 *        id:
 *          type: string
 *        finstitutionname:
 *          type: string
 *        password_hash:
 *          type: string
 *        email:
 *          type: string
 *        roles:
 *          type: array
 *          items:
 *            type: string
 *        isActive:
 *          type: boolean
 *        createdAt:
 *          type: string
 *        updatedAt:
 *          type: string
 */

const router = express.Router();
/**
 * @swagger
 * /api/finstitutions:
 *   get:
 *     summary: Returns a list of finstitutions
 *     tags: [Finstitutions]
 *     responses:
 *       200:
 *         description: A list of finstitutions
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Finstitution'
 */
router.get('/', controller.enlist);

/**
 * @swagger
 * /api/finstitutions:
 *   post:
 *     summary: Create a new finstitution
 *     tags: [Finstitutions]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Finstitution'
 *     responses:
 *       201:
 *         description: Finstitution created
 */
router.post('/', controller.create);

export default router;
