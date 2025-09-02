// Swagger documentation for Finstitution schema and Finstitution routes

import express from 'express';
import * as controller from '../controllers/finstitutionController';

/**
 * @swagger
 * tags:
 *   name: Finstitutions
 *   description: API for managing finstitutions
 */

// Create swagger schema documentation of Finstitution to be added in .ts file in /** format

/**
 * @swagger
 * components:
 *   schemas:
 *     Finstitution:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the financial institution.
 *         finstitutionname:
 *           type: string
 *           description: Name of the financial institution.
 *         finstitutiontype:
 *           type: string
 *           description: Type of the financial institution (e.g., bank, credit union).
 *         finstitutioncode:
 *           type: string
 *           description: Code associated with the financial institution.
 *         finstitutionurl:
 *           type: string
 *           format: uri
 *           description: URL of the financial institution's website.
 *         finstitutionlogo:
 *           type: string
 *           format: uri
 *           description: URL of the financial institution's logo.
 *         finstitutionstatus:
 *           type: string
 *           description: Status of the financial institution (e.g., active, inactive).
 *         finstitutionlanguage:
 *           type: string
 *           description: Language used by the financial institution.
 *         finstitutionproducts:
 *           type: array
 *           items:
 *             type: string
 *             description: List of products offered by the financial institution.
 *         onBoardedOn:
 *           type: string
 *           format: date-time
 *           description: Date when the financial institution was onboarded.
 *         isActive:
 *           type: boolean
 *           description: Indicates if the financial institution is currently active.
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Timestamp when the record was created.
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Timestamp when the record was last updated. 
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
