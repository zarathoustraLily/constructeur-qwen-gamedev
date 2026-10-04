:github_url: hide

.. _class_CharacterBody2D:

CharacterBody2D
===============

**Inherits:** :ref:`PhysicsBody2D<class_PhysicsBody2D>` **<** :ref:`Node<class_Node>`

A 2D physics body specialized for characters moved by script.

.. rst-class:: classref-introduction-group

Description
-----------

Use :ref:`move_and_slide()<class_CharacterBody2D_method_move_and_slide>` to move.

Methods
-------

.. table::

   +------+------+
   | bool | x    |
   +------+------+

.. rst-class:: classref-descriptions-group

Method Descriptions
-------------------

.. _class_CharacterBody2D_method_move_and_slide:

.. rst-class:: classref-method

:ref:`bool<class_bool>` **move_and_slide**\ (\ ) :ref:`🔗<class_CharacterBody2D_method_move_and_slide>`

Moves the body based on velocity.

.. rst-class:: classref-item-separator

----

.. _class_CharacterBody2D_method_is_on_floor:

.. rst-class:: classref-method

:ref:`bool<class_bool>` **is_on_floor**\ (\ ) |const|

Returns true if the body collided with the floor.
