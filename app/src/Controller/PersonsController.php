<?php

namespace App\Controller;

use App\Entity\Person;
use App\Repository\PersonRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/persons')]
class PersonsController extends AbstractController
{
    #[Route('/', name: 'person_list', methods: ['GET'])]
    public function list(PersonRepository $repo): Response
    {
        return $this->render('person/list.html.twig', [
            'persons' => $repo->findAll(),
        ]);
    }

    #[Route('/new', name: 'person_new', methods: ['GET', 'POST'])]
    public function new(Request $request, EntityManagerInterface $em): Response
    {
        $person = new Person();

        if ($request->isMethod('POST')) {
            $person->setFullName($request->request->get('fullName'));
            $person->setEmail($request->request->get('email'));
            $person->setPhone($request->request->get('phone'));

            $em->persist($person);
            $em->flush();

            $this->addFlash('success', 'Osoba została dodana.');
            return $this->redirectToRoute('person_list');
        }

        return $this->render('person/form.html.twig', [
            'person' => $person,
            'mode' => 'create',
        ]);
    }

    #[Route('/{id}/edit', name: 'person_edit', methods: ['GET', 'POST'])]
    public function edit(Person $person, Request $request, EntityManagerInterface $em): Response
    {
        if ($request->isMethod('POST')) {
            $person->setFullName($request->request->get('fullName'));
            $person->setEmail($request->request->get('email'));
            $person->setPhone($request->request->get('phone'));

            $em->flush();

            $this->addFlash('success', 'Dane osoby zaktualizowane.');
            return $this->redirectToRoute('person_list');
        }

        return $this->render('person/form.html.twig', [
            'person' => $person,
            'mode' => 'edit',
        ]);
    }

    #[Route('/{id}/delete', name: 'person_delete', methods: ['POST'])]
    public function delete(Person $person, EntityManagerInterface $em): Response
    {
        $em->remove($person);
        $em->flush();

        $this->addFlash('success', 'Osoba została usunięta.');
        return $this->redirectToRoute('person_list');
    }
}
