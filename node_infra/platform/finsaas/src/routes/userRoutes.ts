// Swagger documentation for User schema and User routes

import express from 'express';
import * as controller from '../controllers/userController';

/**
 * @swagger
 * tags:
 *   name: Users
 *   description: API for managing users
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *        id:
 *          type: string
 *        username:
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
 * /api/users:
 *   get:
 *     summary: Returns a list of users
 *     tags: [Users]
 *     responses:
 *       200:
 *         description: A list of users
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 */
router.get('/', controller.enlist);

/**
 * @swagger
 * /api/users:
 *   post:
 *     summary: Create a new user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/User'
 *     responses:
 *       201:
 *         description: User created
 */
router.post('/', controller.create);

export default router;
