/**
 * @swagger
 * tags:
 *   name: Tenants
 *   description: API for managing tenants
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Tenant:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         name:
 *           type: string
 *         domain:
 *           type: string
 *         isActive:
 *           type: boolean
 *         createdAt:
 *           type: string
 *         updatedAt:
 *           type: string
 */

import { Router } from 'express';
import { basicAuth } from '../middlewares/basicAuth';
import * as controller from '../controllers/tenantController';
import { AuthRequest } from '../types/authRequest';

const router = Router();

/**
 * @swagger
 * /api/tenants/secure-data:
 *   get:
 *     summary: Returns secured data for authenticated user
 *     tags: [Tenants]
 *     description: Requires Basic Authentication
 *     security:
 *       - basicAuth: []
 *     responses:
 *       200:
 *         description: Successful response with username
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Hello, alice
 *       401:
 *         description: Unauthorized - invalid or missing credentials
 */
router.get('/secure-data', basicAuth, (req, res) => {
    // log request details
  console.log(`Request Method: ${req.method}, Request URL: ${req.url}`);
  console.log(`Request Headers: ${JSON.stringify(req.headers)}`);

  const user = (req as AuthRequest).user;

  if (user && user.username) {
    res.json({ message: `Hello, ${user.username}` });
  } else {
    res.status(401).json({ message: 'Unauthorized: user not found' });
  }
});

/**
 * @swagger
 * /api/tenants:
 *   get:
 *     summary: Get all tenants
 *     tags: [Tenants]
 *     responses:
 *       200:
 *         description: List of tenants
 */
router.get('/', controller.getAll);

/**
 * @swagger
 * /api/tenants/{id}:
 *   get:
 *     summary: Get tenant by ID
 *     tags: [Tenants]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Tenant found
 *       404:
 *         description: Tenant not found
 */
router.get('/:id', controller.getById);

/**
 * @swagger
 * /api/tenants:
 *   post:
 *     summary: Create a new tenant
 *     tags: [Tenants]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Tenant'
 *     responses:
 *       201:
 *         description: Tenant created
 */
router.post('/', controller.create);

/**
 * @swagger
 * /api/tenants/{id}:
 *   put:
 *     summary: Update tenant by ID
 *     tags: [Tenants]
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
 *             $ref: '#/components/schemas/Tenant'
 *     responses:
 *       200:
 *         description: Tenant updated
 *       404:
 *         description: Tenant not found
 */
router.put('/:id', controller.update);

/**
 * @swagger
 * /api/tenants/{id}:
 *   delete:
 *     summary: Delete tenant by ID
 *     tags: [Tenants]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       204:
 *         description: Tenant deleted
 *       404:
 *         description: Tenant not found
 */
router.delete('/:id', controller.remove);

export default router;

